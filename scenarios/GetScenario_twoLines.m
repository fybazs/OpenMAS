function [ objectIndex ] = GetScenario_twoLines(varargin)
% This scenario constructs the second evaluation scenario 

fprintf('[SCENARIO]\tGetting a scenario defined by two opposing lines of agents.\n');

%% SCENARIO INPUT HANDLING ////////////////////////////////////////////////
% DEFAULT INPUT CONDITIONS
defaultConfig = struct('file','scenario.mat',...
                       'agents',[],...
                       'separation',10,...   
                       'agentVelocity',0,...
                       'agentRadius',0.5,...    % Diameter of 1m
                       'waypoints',[],...
                       'waypointRadius',0.5,... % Diameter of 1m
                       'padding',2,...
                       'noiseFactor',0,...
                       'plot',0);
                   
% Instanciate the scenario builder
SBinstance = scenarioBuilder();
% Parse user inputs 
[inputConfig] = SBinstance.configurationParser(defaultConfig,varargin);
% AGENT CONDITIONS
agentIndex = inputConfig.agents;                                           % Declare the agent set
agentNumber = numel(agentIndex);                                           % Declare the number of agents

% WE DIVID THE NUMBER OF AGENTS INTO TWO GROUPS, ONE FOR EACH LINE, AND
% CREATE ASSOCIATED PAIRS OF WAYPOINTS
assert(mod(agentNumber,2) == 0,'There must be an equal number of agents in this scenario.');

% SPLIT THE AGENTS INTO GROUPS
agentSetA = agentIndex(1:agentNumber/2);
agentSetB = agentIndex((agentNumber/2)+1:end);

% GLOBAL CONFIGURATION PARAMETERS
xSpacing = inputConfig.padding*inputConfig.agentRadius;
xLimit = (agentNumber/2)*xSpacing;
waypointLineSeparation = 12;
setAHeadings =  [0;1;0];
setBHeadings = -[0;1;0];

%% /////////////////// BUILD THE AGENTS GLOBAL STATES /////////////////////
% SCENARIO BUILDER OBJECT 
% agentScenario = SBinstance('objects',(agentNumber/2));

% CONFIGURATION FOR THE FIRST SET OF AGENTS
[agentConfigA] = SBinstance.line(...
    'objects',agentNumber/2,...
    'pointA',[0;-inputConfig.separation;0],...
    'pointB',[2*xLimit;-inputConfig.separation;0],...
    'heading',setAHeadings,...
    'velocities',inputConfig.agentVelocity,...
    'radius',inputConfig.agentRadius);
[agentConfigB] = SBinstance.line(...
    'objects',agentNumber/2,...
    'pointA',[0;inputConfig.separation;0],...
    'pointB',[2*xLimit;inputConfig.separation;0],...
    'heading',setBHeadings,...
    'velocities',inputConfig.agentVelocity,...
    'radius',inputConfig.agentRadius);

%% REBUILD THE AGENT INDEX UNDER THIS CONFIGURATION
% MOVE THROUGH THE AGENTS AND INITIALISE WITH GLOBAL PROPERTIES
fprintf('[SCENARIO]\tAssigning agent global parameters...\n'); 
for index = 1:(agentNumber/2)
    % AGENT SET A
    agentSetA{index}.VIRTUAL.radius = inputConfig.agentRadius;             % Regulate agent radius
    agentSetA{index}.VIRTUAL.globalPosition = agentConfigA.positions(:,index) + inputConfig.noiseFactor*[randn(2,1);0]; 
    agentSetA{index}.VIRTUAL.globalVelocity = agentConfigA.velocities(:,index);
    agentSetA{index}.VIRTUAL.quaternion     = agentConfigA.quaternions(:,index);
    % AGENT SET B
    agentSetB{index}.VIRTUAL.radius = inputConfig.agentRadius;             % Regulate agent radius
    agentSetB{index}.VIRTUAL.globalPosition = agentConfigB.positions(:,index) + inputConfig.noiseFactor*[randn(2,1);0]; 
    agentSetB{index}.VIRTUAL.globalVelocity = agentConfigB.velocities(:,index);
    agentSetB{index}.VIRTUAL.quaternion     = agentConfigB.quaternions(:,index);
end

%% //////////////// BUILD THE WAYPOINT GLOBAL STATES //////////////////////
% CONFIGURATION FOR THE FIRST SET OF OBJECTS
[waypointConfigA] = SBinstance.line(...
    'objects',agentNumber/2,...
    'pointA',[0;waypointLineSeparation;0],...
    'pointB',[2*xLimit;waypointLineSeparation;0],...
    'heading',-setAHeadings,...
    'velocities',0,...
    'radius',inputConfig.waypointRadius);
[waypointConfigB] = SBinstance.line(...
    'objects',agentNumber/2,...
    'pointA',[0;-waypointLineSeparation;0],...
    'pointB',[2*xLimit;-waypointLineSeparation;0],...
    'heading',-setBHeadings,...
    'velocities',0,...
    'radius',inputConfig.waypointRadius);
                                      
% MOVE THROUGH THE WAYPOINTS AND INITIALISE WITH GLOBAL PROPERTIES
fprintf('[SCENARIO]\tAssigning waypoints to agents.\n'); 
waypointSetA = cell(size(agentSetA)); waypointSetB = cell(size(agentSetB));
for index = 1:(agentNumber/2)
    % WAYPOINT SET A
    waypointSetA{index} = waypoint('radius',inputConfig.waypointRadius,'priority',1,'name',sprintf('WP-%s',agentSetA{index}.name));
    % APPLY GLOBAL STATE VARIABLES
    waypointSetA{index}.VIRTUAL.globalPosition = waypointConfigA.positions(:,index) + inputConfig.noiseFactor*[randn(2,1);0];
    waypointSetA{index}.VIRTUAL.globalVelocity = waypointConfigA.velocities(:,index);
    waypointSetA{index}.VIRTUAL.quaternion     = waypointConfigA.quaternions(:,index);
    waypointSetA{index} = waypointSetA{index}.createAgentAssociation(agentSetA{index});  % Create waypoint with association to agent
    % WAYPOINT SET B
    waypointSetB{index} = waypoint('radius',inputConfig.waypointRadius,'priority',1,'name',sprintf('WP-%s',agentSetB{index}.name));
    % APPLY GLOBAL STATE VARIABLES
    waypointSetB{index}.VIRTUAL.globalPosition = waypointConfigB.positions(:,index) + inputConfig.noiseFactor*[randn(2,1);0];
    waypointSetB{index}.VIRTUAL.globalVelocity = waypointConfigB.velocities(:,index);
    waypointSetB{index}.VIRTUAL.quaternion     = waypointConfigB.quaternions(:,index);
    waypointSetB{index} = waypointSetB{index}.createAgentAssociation(agentSetB{index});  % Create waypoint with association to agent
end

%% /////////////// CLEAN UP ///////////////////////////////////////////////
% BUILD THE COMPLETE OBJECT SET
objectIndex = [agentSetA,agentSetB,waypointSetA,waypointSetB]; 
% PLOT THE SCENE
if inputConfig.plot
    SBinstance.plotObjectIndex(objectIndex);                            % Plot the object index
end
% CLEAR THE REMAINING VARIABLES
clearvars -except objectIndex
% 
fprintf('[SCENARIO]\tDone.\n'); 
end