using ActionModels, HierarchicalGaussianFiltering #For the modeling
using Glob, CSV, DataFrames #For loading the data
using StatsPlots #For plotting
using JLD2 #For saving the results

### READ DATA ###

#Get paths
path_to_this_file = joinpath(splitpath(@__FILE__)[1:(end-2)])
dataPath = "/Volumes/Samsung_T5/SNG/projects/SAPS/data/modeling";
savePath = "/Volumes/Samsung_T5/SNG/projects/SAPS/data/modeling/results";

#Get all the pilot data files by looking for all CSV files in a given folder
# pilot_data_files = glob("*.csv", joinpath(path_to_this_file, "pilots"))
# pilot_data_results = joinpath(savePath, "pilots")
#Get main data files for both SAP and SAPC task by looking for all CSV files in a given folder

main_data_files = glob("*behav.csv", joinpath(dataPath, "main/SAP"))
main_data_results = joinpath(savePath, "main/SAP")

#create empty container for the dataframes
all_dfs = Vector{DataFrame}(undef, length(main_data_files))
#Go through each pilot data file
for (i, filename) in enumerate(main_data_files)
    #Read it in
    single_df = CSV.read(filename, DataFrame, missingstring = "NaN")
    #Add ID column
    single_df.ID .= String(split(basename(filename), "_")[2])
    #Add task type column
 #   if occursin("SAPC", filename)
 #       single_df.task_type .= "SAPC"
  #  elseif occursin("SAP", filename)
 #       single_df.task_type .= "SAP"
  #  else
 #       error("Unknown task type in filename: $filename")
 #   end
    #Add the dataframe to the vector
    all_dfs[i] = single_df
end
#Combine the datasets
data = vcat(all_dfs...)


### CREATE MODEL ###
#Read file with premade function
include("helper_functions/create_action_model.jl")
#Create action model
action_model = create_premade_action_model(4)

#Define independent sessions population model prior
population_model = (;
    action_noise = truncated(Normal(0.1, 1), lower = 0),
    xprob_volatility = truncated(Normal(-6, 2), upper = -1),
)

#Create full model ready for fitting
full_model = create_model(
    action_model,
    population_model,
    data,
    observation_cols = (; observation = :input, observed_avatar = :stimulus),
    action_cols = (; choice = :response),
    session_cols = :ID, #We use ID and task type to define the sessions
    impute_missing_actions = false, #We just ignore the missing actions
    check_parameter_rejections = true, #We check whether the parameters make the HGF break
)


### FIT MODEL ###

# #Load ReverseDiff AD backend
# using ADTypes: AutoReverseDiff
# import ReverseDiff
# ad_type = AutoReverseDiff(; compile = true)

# #Sample the posterior
posterior_chains = sample_posterior!(
    full_model,
    MCMCThreads(),
    n_samples = 1000,
    n_chains = 4,
)
# posterior_chains = sample_posterior!(
#     full_model,
#     MCMCThreads(),
#     n_samples = 250,
#     n_chains = 4,
#     #ad_type = ad_type,
#     init_params = nothing
# )

# @save joinpath(main_data_results,"full_model.jld2") full_model

#Load model
@load joinpath(main_data_results,"full_model.jld2") full_model


#Plot the posterior
plot(posterior_chains)

#Plot the individual parameter estimates
plot(
    full_model,
    :action_noise,
    n = 30,
    ordered_by_median = true,
    group_by = "task_type",
    #xlim = (0, 20),
    #title = "Action noise",
)

#Get a dataframe with the posterior parameter estimates and the std of the uncertainty
posterior_session_params = get_session_parameters!(full_model, :posterior)
posterior_df_medians = summarize(posterior_session_params, median)
posterior_df_std = summarize(posterior_session_params, std)
CSV.write(joinpath(main_data_results,"posterior_session_params_medians.csv"), posterior_df_medians)
CSV.write(joinpath(main_data_results,"posterior_session_params_std.csv"), posterior_df_std)


#Get a dataframe with state trajectories
state_trajectories = get_state_trajectories!(full_model, [:xbinary1_prediction_mean, :xbinary1_prediction_precision, :xprob1_posterior_mean, :xprob1_posterior_precision, :xprob1_value_prediction_error, 
:xbinary2_prediction_mean, :xbinary2_prediction_precision, :xprob2_posterior_mean, :xprob2_posterior_precision, :xprob2_value_prediction_error, 
:xbinary3_prediction_mean, :xbinary3_prediction_precision, :xprob3_posterior_mean, :xprob3_posterior_precision, :xprob3_value_prediction_error, 
:xvol_posterior_mean, :xvol_posterior_precision])

trajectories_df = summarize(state_trajectories, :posterior), median)
CSV.write(joinpath(main_data_results,"state_trajectories.csv"), trajectories_df)


#We can do all the same things with the prior
#Sample the prior
prior_chains = sample_prior!(full_model, n_samples = 1000, n_chains = 2) #use 4 chains for final results

#Plot the prior
plot(prior_chains)

#Get a dataframe with the prior parameter estimates and the std of the uncertainty
prior_session_params = get_session_parameters!(full_model, :prior)
prior_df_medians = summarize(prior_session_params, median)
prior_df_std = summarize(prior_session_params, std)


#Get a dataframe with the posterior state estimates and the std of the uncertainty
#The symbol decides which state to summarize
#Prediction for avatar 1
trajectories_df = summarize(get_state_trajectories!(full_model, :xbinary1_prediction_mean, :prior), median)
CSV.write(joinpath(main_data_results,"prior_face1_prediction_mean.csv"), trajectories_df)

#Prediction for avatar 2
prior_trajectories_df = summarize(get_state_trajectories!(full_model, :xbinary2_prediction_mean, :prior), median)
CSV.write(joinpath(main_data_results,"prior_face2_prediction_mean.csv"), prior_trajectories_df)

#Prediction for avatar 3
prior_trajectories_df = summarize(get_state_trajectories!(full_model, :xbinary3_prediction_mean, :prior), median)
CSV.write(joinpath(main_data_results,"prior_face3_prediction_mean.csv"), prior_trajectories_df)

#Belief for probability parent, avatar 1
prior_trajectories_df = summarize(get_state_trajectories!(full_model, :xprob1_posterior_mean, :prior), median)
CSV.write(joinpath(main_data_results,"prior_face1_posterior_mean.csv"), prior_trajectories_df)

#Prediction error for probability parent for avatar 1
prior_trajectories_df = summarize(get_state_trajectories!(full_model, :xprob1_value_prediction_error, :prior), median)
CSV.write(joinpath(main_data_results,"prior_face1_value_prediction_error.csv"), prior_trajectories_df)

#Belief for probability parent, avatar 2
prior_trajectories_df = summarize(get_state_trajectories!(full_model, :xprob2_posterior_mean, :prior), median)
CSV.write(joinpath(main_data_results,"prior_face2_posterior_mean.csv"), prior_trajectories_df)

#Prediction error for probability parent for avatar 2
prior_trajectories_df = summarize(get_state_trajectories!(full_model, :xprob2_value_prediction_error, :prior), median)
CSV.write(joinpath(main_data_results,"prior_face2_value_prediction_error.csv"), prior_trajectories_df)

#Belief for probability parent, avatar 3
prior_trajectories_df = summarize(get_state_trajectories!(full_model, :xprob3_posterior_mean, :prior), median)
CSV.write(joinpath(main_data_results,"prior_face3_posterior_mean.csv"), prior_trajectories_df)

#Prediction error for probability parent for avatar 3
prior_trajectories_df = summarize(get_state_trajectories!(full_model, :xprob3_value_prediction_error, :prior), median)
CSV.write(joinpath(main_data_results,"prior_face3_value_prediction_error.csv"), prior_trajectories_df)

#Belief mean for overall volatility
prior_trajectories_df = summarize(get_state_trajectories!(full_model, :xvol_posterior_mean, :prior), median)
CSV.write(joinpath(main_data_results,"prior_vol_posterior_mean.csv"), prior_trajectories_df)




#Save the model with everything calculated
@save joinpath(main_data_results,"full_model.jld2") full_model