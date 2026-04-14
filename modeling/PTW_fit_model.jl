using ActionModels, HierarchicalGaussianFiltering #For the modeling
using Glob, CSV, DataFrames #For loading the data
using StatsPlots #For plotting
using JLD2 #For saving the results
using ADTypes: AutoReverseDiff

#Check number of threads
Threads.nthreads()

### CREATE MODEL ###
#Read file with premade function
include("helper_functions/create_action_model.jl")
#Create action model
action_model = create_premade_action_model(4)

#Define independent sessions population model prior
#  Comment out the parameters not to be estimated
population_model = (;
    #The action noise β
    action_noise = truncated(Normal(1, 0.3), lower = 0),

    #The tonic volatility ω₂
    xprob_volatility = truncated(Normal(-6, 2), upper = -1),

    #The tonic volatility ω₃
    xvol_volatility = truncated(Normal(-6, 2), upper = -1),

    #The coupling strength κ₂₁ between probability and binary
    #xbinary_xprob_coupling_strength = truncated(Normal(1, 0.5), lower = 0),

    #The coupling strength κ₃₂ between probability and binary
    xprob_xvol_coupling_strength = truncated(Normal(1, 0.2), lower = 0),
)

### READ DATA ###

#Get paths
path_to_this_file = joinpath(splitpath(@__FILE__)[1:(end-2)])
#dataPath = "/Volumes/Samsung_T5/SNG/projects/SAPS/data/modeling/main/SAP";
#savePath = "/Volumes/Samsung_T5/SNG/projects/SAPS/data/modeling/results/main/SAP";
dataPath = joinpath(path_to_this_file, "modeling", "data")
savePath = joinpath(path_to_this_file, "modeling", "results")
main_data_files = glob("*behav.csv", joinpath(dataPath))

#create empty container for the dataframes
all_dfs = Vector{DataFrame}(undef, length(main_data_files))
#Go through each pilot data file
for (i, filename) in enumerate(main_data_files)
    #Read it in
    single_df = CSV.read(filename, DataFrame, missingstring = "NaN")
    #Add ID column
    single_df.ID .= String(split(basename(filename), "_")[2])
    #Add task type column
   if occursin("SAPC", filename)
       single_df.task_type .= "SAPC"
   elseif occursin("SAP", filename)
       single_df.task_type .= "SAP"
   else
       error("Unknown task type in filename: $filename")
   end
    #Add the dataframe to the vector
    all_dfs[i] = single_df
end
#Combine the datasets
data = vcat(all_dfs...)

########################################
### FIT MDOELS FOR EVERY PARTICIPANT ###
########################################
OVERWRITE_RESULTS = true
USE_SMALL_VERSION = false

#Functions for quantiles
q10(x) = quantile(vec(x), 0.1)
q90(x) = quantile(vec(x), 0.9)
q025(x) = quantile(vec(x), 0.025)
q975(x) = quantile(vec(x), 0.975)

#For the df corresponding to every participant and every task type
#Threads.@threads for df in collect(groupby(data, [:ID, :task_type]))
for df in collect(groupby(data, [:ID, :task_type]))

    ### SETUP ###
    participant_string = "ID_$(df.ID[1])_$(df.task_type[1])"
    #Get path for the resutls for this participant
    chains_savepath = joinpath(savePath, "chains", "chains_$(participant_string).jld2")
    csvs_savepath = joinpath(savePath, "csvs")
    plots_savepath = joinpath(savePath, "plots")

    #create subfolders if they do not exist
    if !isdir(joinpath(savePath, "chains"))
        mkdir(joinpath(savePath, "chains"))
    end
    if !isdir(joinpath(savePath, "csvs"))
        mkdir(joinpath(savePath, "csvs"))
    end
    if !isdir(joinpath(savePath, "plots"))
        mkdir(joinpath(savePath, "plots"))
     end

    #Create full model to fit
    am_model = create_model(
        action_model,
        population_model,
        DataFrame(df),
        observation_cols = (; observation = :input, observed_avatar = :stimulus),
        action_cols = (; choice = :response),
        session_cols = [:ID, :task_type], #We use ID and task type to define the sessions
        impute_missing_actions = false, #We just ignore the missing actions
        check_parameter_rejections = true, #We check whether the parameters make the HGF break
    )

    ### LOAD OR FIT MODEL ###

    #If the file exists, and results should not be overwritten
    if isfile(chains_savepath) && !OVERWRITE_RESULTS

        @warn "results already exist for participant $(df.ID[1]), skipping fitting."

        #Load the results
        @load chains_savepath participant_chains

        #Store the chains in the actionmodels model
        am_model.posterior = ActionModels.ModelFitResult(; chains = chns);

    else

        @warn "fitting model for participant $(df.ID[1])..."

        #Load ReverseDiff AD backend
        ad_type = AutoReverseDiff(; compile = true)

        #If only using the small version
        if USE_SMALL_VERSION
            
            participant_chains = sample_posterior!(
                am_model,
                n_samples = 10,
                n_chains = 1,
            )
            
        else
            
            #If using the large version
            participant_chains = sample_posterior!(
                am_model,
                MCMCSerial(),
                n_samples = 1000,
                n_chains = 4,
                ad_type = ad_type,
            )

        end

        #Save the results
        @save chains_savepath participant_chains

    end

    ### SAVE RESULTS ###
    #Get parameters
    posterior_session_params = get_session_parameters!(am_model, :posterior)

    #Get summaries of the parameters
    posterior_df_medians = summarize(posterior_session_params, median)
    CSV.write(joinpath(csvs_savepath,"params_median_$(participant_string).csv"), posterior_df_medians)
    posterior_df_q10 = summarize(posterior_session_params, q10)
    CSV.write(joinpath(csvs_savepath,"params_q10_$(participant_string).csv"), posterior_df_q10)
    posterior_df_q90 = summarize(posterior_session_params, q90)
    CSV.write(joinpath(csvs_savepath,"params_q90_$(participant_string).csv"), posterior_df_q90)
    posterior_df_q025 = summarize(posterior_session_params, q025)
    CSV.write(joinpath(csvs_savepath,"params_q025_$(participant_string).csv"), posterior_df_q025)
    posterior_df_q975 = summarize(posterior_session_params, q975)
    CSV.write(joinpath(csvs_savepath,"params_q975_$(participant_string).csv"), posterior_df_q975)

    #Prediction for avatar 1
    trajectories = get_state_trajectories!(am_model, :xbinary1_prediction_mean, )
    trajectories_df = summarize(trajectories, median)
    CSV.write(joinpath(csvs_savepath,"$(participant_string)_states_face1_prediction_mean.csv"), trajectories_df)

    #Prediction for avatar 2
    trajectories_df = summarize(get_state_trajectories!(am_model, :xbinary2_prediction_mean, ), median)
    CSV.write(joinpath(csvs_savepath,"$(participant_string)_states_face2_prediction_mean.csv"), trajectories_df)

    #Prediction for avatar 3
    trajectories_df = summarize(get_state_trajectories!(am_model, :xbinary3_prediction_mean, ), median)
    CSV.write(joinpath(csvs_savepath,"$(participant_string)_states_face3_prediction_mean.csv"), trajectories_df)

    #Belief for probability parent, avatar 1
    trajectories_df = summarize(get_state_trajectories!(am_model, :xprob1_posterior_mean, ), median)
    CSV.write(joinpath(csvs_savepath,"$(participant_string)_states_face1_posterior_mean.csv"), trajectories_df)

    #Prediction error for probability parent for avatar 1
    trajectories_df = summarize(get_state_trajectories!(am_model, :xprob1_value_prediction_error, ), median)
    CSV.write(joinpath(csvs_savepath,"$(participant_string)_states_face1_value_prediction_error.csv"), trajectories_df)

    #Belief for probability parent, avatar 2
    trajectories_df = summarize(get_state_trajectories!(am_model, :xprob2_posterior_mean, ), median)
    CSV.write(joinpath(csvs_savepath,"$(participant_string)_states_face2_posterior_mean.csv"), trajectories_df)

    #Prediction error for probability parent for avatar 2
    trajectories_df = summarize(get_state_trajectories!(am_model, :xprob2_value_prediction_error, ), median)
    CSV.write(joinpath(csvs_savepath,"$(participant_string)_states_face2_value_prediction_error.csv"), trajectories_df)

    #Belief for probability parent, avatar 3
    trajectories_df = summarize(get_state_trajectories!(am_model, :xprob3_posterior_mean, ), median)
    CSV.write(joinpath(csvs_savepath,"$(participant_string)_states_face3_posterior_mean.csv"), trajectories_df)

    #Prediction error for probability parent for avatar 3
    trajectories_df = summarize(get_state_trajectories!(am_model, :xprob3_value_prediction_error, ), median)
    CSV.write(joinpath(csvs_savepath,"$(participant_string)_states_face3_value_prediction_error.csv"), trajectories_df)

    #Belief mean for overall volatility
    trajectories_df = summarize(get_state_trajectories!(am_model, :xvol_posterior_mean, ), median)
    CSV.write(joinpath(csvs_savepath,"$(participant_string)_states_vol_posterior_mean.csv"), trajectories_df)

    ### SAVE RESULTS ###
    plt = plot(participant_chains)
    savefig(joinpath(plots_savepath, "parameter_posteriors_$(participant_string).png"))
end