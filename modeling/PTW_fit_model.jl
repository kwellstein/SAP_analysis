using ActionModels, HierarchicalGaussianFiltering #For the modeling
using Glob, CSV, DataFrames #For loading the data
using StatsPlots #For plotting
using JLD2 #For saving the results
using ADTypes: AutoReverseDiff
import ReverseDiff

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
    #xvol_volatility = truncated(Normal(-6, 2), upper = -1),

    #The coupling strength κ₂₁ between probability and binary
    #xbinary_xprob_coupling_strength = truncated(Normal(1, 0.5), lower = 0),

    #The coupling strength κ₃₂ between probability and binary
    xprob_xvol_coupling_strength = truncated(Normal(1, 0.2), lower = 0),
)

### READ DATA ###

#Get paths
path_to_this_file = joinpath(splitpath(@__FILE__)[1:(end-2)])
dataPath = "/Volumes/Samsung_T5/SNG/projects/SAPS/data/modeling/main/SAP";
savePath = "/Volumes/Samsung_T5/SNG/projects/SAPS/data/modeling/results/main/SAP";
main_data_files = glob("*behav.csv", joinpath(dataPath, "main/SAP"))
main_data_results = joinpath(savePath, "main/SAP")

    
#Get all the pilot data files by looking for all CSV files in a given folder
#dataPath = joinpath(path_to_this_file, "modeling", "data", "main")
#savePath = joinpath(path_to_this_file, "modeling", "results", "main")
#Get main data files for both SAP and SAPC task by looking for all CSV files in a given folder
main_data_files = glob("*.csv", dataPath)
main_data_results = joinpath(savePath)

#create empty container for the dataframes

# data = Vector{DataFrame}(undef, length(main_data_files))
#Go through each pilot data file
for filename in enumerate(main_data_files)
    #Read it in
     data = CSV.read(filename[2], DataFrame, missingstring = "NaN")
    #Add ID column
     ID = String(split(basename(filename[2]), "_")[2])

### SUBSET THE DATA HERE ###
#Create full model ready for fitting
full_model = create_model(
    action_model,
    population_model,
    data,
    observation_cols = (; observation = :input, observed_avatar = :stimulus),
    action_cols = (; choice = :response),
    #session_cols = :ID, #:task_type], #We use ID and task type to define the sessions
    impute_missing_actions = false, #We just ignore the missing actions
    check_parameter_rejections = true, #We check whether the parameters make the HGF break
)


### FIT MODEL ###

### Small version to test ###
# #Sample the posterior
posterior_chains = sample_posterior!(
    full_model,
    n_samples = 10,
    n_chains = 1,
   # init_params = :MAP
)

#Load ReverseDiff AD backend
ad_type = AutoReverseDiff(; compile = true)

#posterior_chains = sample_posterior!(
#    full_model,
#    MCMCThreads(),
#    n_samples = 250,
#    n_chains = 4,
#    ad_type = ad_type,
#    init_params = :MAP
#)

@save joinpath(main_data_results,"full_model.jld2") full_model

#Load model
# @load joinpath(main_data_results,"full_model.jld2") full_model


#Plot the posterior
plot(posterior_chains)

# #Plot the individual parameter estimates
# plot(
#     full_model,
#     :xprob_volatility, #choose which parameter to plot
#     n = n_participants,
#     ordered_by_median = true,
#     group_by = "task_type",
#     #xlim = (0, 20),
#     #title = "Action noise",
# )

#Get a dataframe with the posterior parameter estimates and the std of the uncertainty
posterior_session_params = get_session_parameters!(full_model, :posterior)
posterior_df_medians = summarize(posterior_session_params, median)
posterior_df_std = summarize(posterior_session_params, std)
CSV.write(joinpath(main_data_results, "$ID _posterior_session_params_medians.csv"), posterior_df_medians)
CSV.write(joinpath(main_data_results,"posterior_session_params_std.csv"), posterior_df_std)

#Get a dataframe with the posterior state estimates and the std of the uncertainty
#The symbol decides which state to summarize
#Prediction for avatar 1
trajectories_df = summarize(get_state_trajectories!(full_model, :xbinary1_prediction_mean, ), median)
CSV.write(joinpath(main_data_results,"face1_prediction_mean.csv"), trajectories_df)

#Prediction for avatar 2
trajectories_df = summarize(get_state_trajectories!(full_model, :xbinary2_prediction_mean, ), median)
CSV.write(joinpath(main_data_results,"face2_prediction_mean.csv"), trajectories_df)

#Prediction for avatar 3
trajectories_df = summarize(get_state_trajectories!(full_model, :xbinary3_prediction_mean, ), median)
CSV.write(joinpath(main_data_results,"face3_prediction_mean.csv"), trajectories_df)

#Belief for probability parent, avatar 1
trajectories_df = summarize(get_state_trajectories!(full_model, :xprob1_posterior_mean, ), median)
CSV.write(joinpath(main_data_results,"face1_posterior_mean.csv"), trajectories_df)

#Prediction error for probability parent for avatar 1
trajectories_df = summarize(get_state_trajectories!(full_model, :xprob1_value_prediction_error, ), median)
CSV.write(joinpath(main_data_results,"face1_value_prediction_error.csv"), trajectories_df)

#Belief for probability parent, avatar 2
trajectories_df = summarize(get_state_trajectories!(full_model, :xprob2_posterior_mean, ), median)
CSV.write(joinpath(main_data_results,"face2_posterior_mean.csv"), trajectories_df)

#Prediction error for probability parent for avatar 2
trajectories_df = summarize(get_state_trajectories!(full_model, :xprob2_value_prediction_error, ), median)
CSV.write(joinpath(main_data_results,"face2_value_prediction_error.csv"), trajectories_df)

#Belief for probability parent, avatar 3
trajectories_df = summarize(get_state_trajectories!(full_model, :xprob3_posterior_mean, ), median)
CSV.write(joinpath(main_data_results,"face3_posterior_mean.csv"), trajectories_df)

#Prediction error for probability parent for avatar 3
trajectories_df = summarize(get_state_trajectories!(full_model, :xprob3_value_prediction_error, ), median)
CSV.write(joinpath(main_data_results,"face3_value_prediction_error.csv"), trajectories_df)

#Belief mean for overall volatility
trajectories_df = summarize(get_state_trajectories!(full_model, :xvol_posterior_mean, ), median)
CSV.write(joinpath(main_data_results,"vol_posterior_mean.csv"), trajectories_df)


#Save the model with everything calculated
@save joinpath(main_data_results,"full_model.jld2") full_model
end