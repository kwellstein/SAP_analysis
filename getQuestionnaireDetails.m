function options = getQuestionnaireDetails(options)

options.quest(1).name = "SPQ";
options.quest(1,1).ideasOfReference       = ["spq01","spq10","spq19","spq28","spq37","spq45","spq53","spq60","spq63"];
options.quest(1,1).excessiveSocialAnxiety = ["spq02","spq11","spq20","spq29","spq38","spq46","spq54","spq71"];
options.quest(1,1).magicalThinking        = ["spq03","spq12","spq21","spq30","spq39","spq47","spq55"];
options.quest(1,1).unusualPerceptualExperiences = ["spq04","spq13","spq22","spq31","spq40","spq48","spq56","spq61","spq64"];
options.quest(1,1).eccentricBehaviour     = ["spq05","spq14","spq23","spq32","spq67","spq70","spq74"];
options.quest(1,1).noCloseFriends         = ["spq06","spq15","spq24","spq33","spq41","spq49","spq57","spq62","spq66"];
options.quest(1,1).oddSpeech              = ["spq07","spq16","spq25","spq34","spq42","spq50","spq58","spq69","spq72"];
options.quest(1,1).constrictedAffect      = ["spq08","spq17","spq26","spq35","spq43","spq51","spq68","spq73"];
options.quest(1,1).suspiciousness         = ["spq09","spq18","spq27","spq36","spq44","spq52","spq59","spq65"];

options.quest(1,2).constrictedAffect = {"People sometimes find me aloof and distant.",...
    "I am not good at expressing my true feelings by the way I talk and look.",...
    "I rarely laugh and smile.","My ''nonverbal'' communication (smiling and nodding during a conversation) is not very good.",...
    "I am poor at returning social courtesies and gestures.","I tend to avoid eye contact when conversing with others.",...
    "I do not have an expressive and lively way of speaking.","I tend to keep my feelings to myself."};

options.quest(2).name = "SPQ";
options.quest(2,1).ideasOfReference       = ["spq01_v2","spq10_v2","spq19_v2","spq28_v2","spq37_v2","spq45_v2","spq53_v2","spq60_v2","spq63_v2"];
options.quest(2,1).excessiveSocialAnxiety = ["spq02_v2","spq11_v2","spq20_v2","spq29_v2","spq38_v2","spq46_v2","spq54_v2","spq71_v2"];
options.quest(2,1).magicalThinking        = ["spq03_v2","spq12_v2","spq21_v2","spq30_v2","spq39_v2","spq47_v2","spq55_v2"];
options.quest(2,1).unusualPerceptualExperiences = ["spq04_v2","spq13_v2","spq22_v2","spq31_v2","spq40_v2","spq48_v2","spq56_v2","spq61_v2","spq64_v2"];
options.quest(2,1).eccentricBehaviour     = ["spq05_v2","spq14_v2","spq23_v2","spq32_v2","spq67_v2","spq70_v2","spq74_v2"];
options.quest(2,1).noCloseFriends         = ["spq06_v2","spq15_v2","spq24_v2","spq33_v2","spq41_v2","spq49_v2","spq57_v2","spq62_v2","spq66_v2"];
options.quest(2,1).oddSpeech              = ["spq07_v2","spq16_v2","spq25_v2","spq34_v2","spq42_v2","spq50_v2","spq58_v2","spq69_v2","spq72_v2"];
options.quest(2,1).constrictedAffect      = ["spq08_v2","spq17_v2","spq26_v2","spq35_v2","spq43_v2","spq51_v2","spq68_v2","spq73_v2"];
options.quest(2,1).suspiciousness         = ["spq09_v2","spq18_v2","spq27_v2","spq36_v2","spq44_v2","spq52_v2","spq59_v2","spq65_v2"];

options.quest(2,2).constrictedAffect = {"People sometimes find me aloof and distant.",...
    "I am not good at expressing my true feelings by the way I talk and look.",...
    "I rarely laugh and smile.","My ''nonverbal'' communication (smiling and nodding during a conversation) is not very good.",...
    "I am poor at returning social courtesies and gestures.","I tend to avoid eye contact when conversing with others.",...
    "I do not have an expressive and lively way of speaking.","I tend to keep my feelings to myself."};

options.quest(3,1).name = "CAPE";
options.quest(3,1).positiveSymptoms_freq    = ["cape02_frequency","cape05_frequency","cape06_frequency",...
    "cape07_frequency","cape10_frequency","cape11_frequency","cape13_frequency","cape15_frequency", "cape17_frequency",...
    "cape20_frequency","cape22_frequency", "cape24_frequency","cape26_frequency","cape28_frequency", "cape30_frequency",...
    "cape31_frequency","cape33_frequency", "cape34_frequency","cape41_frequency","cape42_frequency"];
options.quest(3,1).positiveSymptoms_distr     = ["cape02_distress","cape05_distress","cape06_distress",...
    "cape07_distress","cape10_distress","cape11_distress","cape13_distress","cape15_distress", "cape17_distress",...
    "cape20_distress","cape22_distress", "cape24_distress","cape26_distress","cape28_distress", "cape30_distress",...
    "cape31_distress","cape33_distress", "cape34_distress","cape41_distress","cape42_distress"];
options.quest(3,1).negativeSymptoms_freq   = ["cape03_frequency","cape04_frequency","cape08_frequency",...
    "cape16_frequency","cape18_frequency","cape21_frequency","cape23_frequency", "cape25_frequency","cape27_frequency",...
    "cape29_frequency","cape32_frequency","cape35_frequency","cape36_frequency","cape37_frequency"];
options.quest(3,1).negativeSymptoms_distr   = ["cape03_distress","cape04_distress","cape08_distress",...
    "cape16_distress","cape18_distress","cape21_distress","cape23_distress", "cape25_distress","cape27_distress",...
    "cape29_distress","cape32_distress","cape35_distress","cape36_distress","cape37_distress"];
options.quest(3,1).depressiveSymptoms_freq  = ["cape01_frequency","cape09_frequency", "cape12_frequency",...
   "cape14_frequency","cape19_frequency","cape38_frequency","cape39_frequency","cape40_frequency"];
options.quest(3,1).depressiveSymptoms_distr = ["cape01_distress","cape09_distress", "cape12_distress",...
   "cape14_distress","cape19_distress","cape38_distress","cape39_distress","cape40_distress"];

options.quest(4,1).name = "BISBAS";
options.quest(4,1).activation_drive     = ["bisbas03","bisbas09","bisbas12","bisbas21"];
options.quest(4,1).activation_funSeek   = ["bisbas05","bisbas10","bisbas15","bisbas20"];
options.quest(4,1).activation_rewardResp= ["bisbas03","bisbas09","bisbas12","bisbas21","bisbas05","bisbas10","bisbas15","bisbas20"];
options.quest(4,1).activation           = ["bisbas04","bisbas07","bisbas14","bisbas18","bisbas23"];
options.quest(4,1).inhibition           = ["bisbas02","bisbas08","bisbas13","bisbas16","bisbas19","bisbas22","bisbas24"];

options.quest(5,1).name = "MAIA";
options.quest(5,1).noticing       = ["maia01","maia02","maia04"];
options.quest(5,1).notDistracting = ["maia05","maia06","maia07","maia08","maia09","maia10"]; % reverse coded
options.quest(5,1).notWorrying    = ["maia11","maia12","maia13","maia14","maia15"]; % 11,12,15 reverse coded
options.quest(5,1).attentionReg   = ["maia16","maia17","maia18","maia19","maia20","maia21","maia22"];
options.quest(5,1).emotAwareness  = ["maia23","maia24","maia25","maia26","maia27"];
options.quest(5,1).selfRegulation = ["maia28","maia29","maia30","maia31"];
options.quest(5,1).bodyListening  = ["maia32","maia33","maia34"];
options.quest(5,1).trusting       = ["maia35","maia36","maia37"];

options.quest(6,1).name = "BPQ";
options.quest(6,1).bodyAwareness = ["bpq01","bpq02","bpq03","bpq04","bpq05","bpq06","bpq07","bpq08","bpq09","bpq10",...
                                        "bpq11","bpq12","bpq13","bpq14","bpq15","bpq16","bpq17","bpq18","bpq19","bpq20",... 
                                         "bpq21","bpq22","bpq23","bpq24","bpq25","bpq26"];
options.quest(6,1).ansReactivity = ["bpq27","bpq28","bpq29","bpq30","bpq31","bpq32",...
                                        "bpq33","bpq34","bpq35","bpq36","bpq37","bpq38","bpq39","bpq40","bpq41","bpq42",... 
                                        "bpq43","bpq44","bpq45","bpq46"];

end