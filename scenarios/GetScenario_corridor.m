function [ objectIndex ] = GetScenario_corridor(varargin)
% This function generates the four agent, four obstacle example, termed
% scenario D in the formation control/ collision avoidance study.

fprintf('[SCENARIO]\tGetting the four agent, four obstacle formation control example.\n');

%% SCENARIO INPUT HANDLING ////////////////////////////////////////////////
% DEFAULT INPUT CONDITIONS
defaultConfig = struct('file','scenario.mat',...
                       'origin',zeros(3,1),...
                       'agents',[],...
                       'agentVelocity',0,...
                       'agentSpacing',5,...
                       'waypointRadius',1,...
                       'plot',0,...
                       'noiseFactor',0,...
                       'adjacencyMatrix',[]); 
                       
% Instanciate the scenario builder
SBinstance = scenarioBuilder();
% Parse user inputs 
[inputConfig] = SBinstance.configurationParser(defaultConfig,varargin);

% Input sanity check
inputConfig.agents = reshape(inputConfig.agents,[numel(inputConfig.agents),1]); % Ensure formatting
assert(~isempty(inputConfig.agents),'Please provide an agent vector.');

% DESIGN THE ADJACENCY MATRIX
if isempty(inputConfig.adjacencyMatrix)
    fprintf('[SCENARIO]\tUsing the default adjacency matrix.');
    % The adjacency matrix describes the desired separation between each
    % agents. 
    inputConfig.adjacencyMatrix = double(~eye(numel(inputConfig.agents)));  % DESIGN AN ADJACENCY MATRIX
end

% /////////////////// DESIGN THE OBSTACLE CONFIGURATION ///////////////////
% This scenario has a constant obstacle configuration irrespect of the
% objects in the field.

corridorWidth = 6;
Yscale = 10;
offsetPosition = Yscale + corridorWidth/2; 

obstacleIndex = cell(2,1);
obstacleIndex{1} = obstacle_cuboid('name','Wall_A','Xscale',10,'Zscale',10,'Yscale',Yscale);
obstacleIndex{1}.VIRTUAL.globalPosition = [20; offsetPosition;0];
obstacleIndex{2} = obstacle_cuboid('name','Wall_B','Xscale',10,'Zscale',10,'Yscale',Yscale);
obstacleIndex{2}.VIRTUAL.globalPosition = [20;-offsetPosition;0];


% ///////////////////// DESIGN THE AGENT CONFIGURATION ////////////////////
agentNumber = numel(inputConfig.agents);
agentIndex  = inputConfig.agents;
% Define the agent scenario
diskConfig = SBinstance.planarDisk(...
    'objects',agentNumber,...
    'pointA',inputConfig.origin - [0;0;1],...
    'pointB',inputConfig.origin,...              % Center of the disk
    'scale',inputConfig.agentSpacing);

for index = 1:agentNumber
    % ASSIGN THE GLOBAL ADJACENCY MATRIX 
    if isprop(agentIndex{index},'adjacencyMatrix')
        agentIndex{index}.adjacencyMatrix = inputConfig.adjacencyMatrix;
    end
    % ASSIGN GLOBAL PROPERTIES
    agentIndex{index}.VIRTUAL.globalPosition = diskConfig.positions(:,index);
    agentIndex{index}.VIRTUAL.globalVelocity = diskConfig.velocities(:,index);
    agentIndex{index}.VIRTUAL.quaternion = diskConfig.quaternions(:,index);
end

% ////////// DESIGN THE REPRESENTATIVE WAYPOINT CONFIGURATION /////////////
fprintf('[SCENARIO]\tAssigning waypoint definitions:\n'); 
waypointIndex = cell(agentNumber,1);
for index = 1:agentNumber
    nameString = sprintf('WP-%s',agentIndex{index}.name);
    waypointIndex{index,1} = waypoint('radius',inputConfig.waypointRadius,'name',nameString);
    % APPLY GLOBAL STATE VARIABLES
    waypointIndex{index,1}.VIRTUAL.globalPosition = [40;0;0];
    waypointIndex{index,1}.VIRTUAL.globalVelocity = zeros(3,1);
    waypointIndex{index,1} = waypointIndex{index}.createAgentAssociation(agentIndex{index},5);  % Create waypoint with association to agent
end

% /////////////////////////////// CLEAN UP ////////////////////////////////
% BUILD THE COMPLETE OBJECT SET
objectIndex = [agentIndex;obstacleIndex;waypointIndex]; 
% PLOT THE SCENE
if inputConfig.plot
    scenarioBuilder.plotObjectIndex(objectIndex);                          % Plot the object index
end
% CLEAR THE REMAINING VARIABLES
clearvars -except objectIndex
end