classdef atlasDistanceScorer
    %ATLASDISTANCESCORER Used to score a registration using euclidean
    %distance. Contains the location of the points in all brains+atlas.
    %   Detailed explanation goes here
    
    properties
        %points are written down in TissueVision-XYZ format (coronal plane-based, y axis inverted compared to .nii)
        %coordinates are specified in VOXELS INDICES, starting from 0 in
        %X/Y and 1 in Z (imageJ-style)
        atlasPointList = struct('IDX', [], 'name', '', 'coords', []);
        brainPointList;
        defField;
        atlasScale = 0.0125; %scale in mm/voxel
        atlasHeight = 720; %
        brainHeight;
    end
    
    methods
        
        function obj = atlasDistanceScorer(brainName, deformationFieldNii)
            obj.brainPointList = obj.getBrainPointList(brainName);
            obj.defField = deformationFieldNii;
            obj.atlasPointList = [obj.atlasPointList struct('IDX', 1,'name', 'Frontal_Middle_1', 'coords', [520 344 796])];
            obj.atlasPointList = [obj.atlasPointList struct('IDX', 2,'name', 'Frontal_Right_2', 'coords', [578 349 796])];
            obj.atlasPointList = [obj.atlasPointList struct('IDX', 3,'name', 'Frontal_Left_2', 'coords', [461 348 796])];
            obj.atlasPointList = [obj.atlasPointList struct('IDX', 4,'name', 'Anterior_Commissure_Right', 'coords', [606 490 734])];
            obj.atlasPointList = [obj.atlasPointList struct('IDX', 5,'name', 'Anterior_Commissure_Left', 'coords', [434 490 734])];
            obj.atlasPointList = [obj.atlasPointList struct('IDX', 7,'name', 'Corpus_Callosum_Middle', 'coords', [520 252 636])];
            obj.atlasPointList = [obj.atlasPointList struct('IDX', 8,'name', 'Hippocampus_Middle', 'coords', [520 215 513])];
            obj.atlasPointList = [obj.atlasPointList struct('IDX', 9,'name', 'Interpeduncular_Nucleus_Right', 'coords', [562 497 438])];
            obj.atlasPointList = [obj.atlasPointList struct('IDX', 10,'name', 'Interpeduncular_Nucleus_Middle', 'coords', [520 497 438])];
            obj.atlasPointList = [obj.atlasPointList struct('IDX', 11,'name', 'Interpeduncular_Nucleus_Left', 'coords', [478 497 438])];
            obj.atlasPointList = [obj.atlasPointList struct('IDX', 12,'name', 'Pontine_Nucleus_Middle', 'coords', [520 530 434])];
            obj.atlasPointList = [obj.atlasPointList struct('IDX', 13,'name', 'Cortex_Middle', 'coords', [520 110 435])];
            obj.brainHeight = sharedParams().getBrainHeight(brainName);
        end
        
        function result = getDistanceStruct(obj)
            result = struct('IDX', [], 'name', '', 'atlasPos', [], 'brainPos', [], 'distance', []);
            for i = 1:numel(obj.brainPointList)
                brainPoint = obj.brainPointList(i);
                atlasPoint = obj.atlasPointList(strcmp({obj.atlasPointList.name},brainPoint.name));
                if isempty(atlasPoint)
                    warning(['Point ' brainPoint.name ' is unknown to me']);
                end
                atlasPos = [atlasPoint.coords(1)+1 atlasPoint.coords(3) obj.atlasHeight-atlasPoint.coords(2)]*obj.atlasScale;
                brainPos = obj.defField.img(brainPoint.coords(1)+1, brainPoint.coords(3), obj.brainHeight-brainPoint.coords(2),1,:);
                brainPos = brainPos(:)';
                distance = pdist2(atlasPos, brainPos, 'euclidean');
                result = [result struct('IDX', atlasPoint.IDX, 'name', atlasPoint.name, 'atlasPos', atlasPos, 'brainPos', brainPos, 'distance', distance)];
            end
        end
        
        function result = pointTest(obj, brainPos)
            result = obj.defField.img(brainPos(1)+1, brainPos(3), obj.atlasHeight-brainPos(2),1,:);
            result = result(:)';
        end
    end
    
    methods (Static)
        function result=getBrainPointList(brainName)
            switch brainName
                case 'MV_Ntsr1_169'
                    result = struct('IDX', 1,'name', 'Frontal_Middle_1', 'coords', [533 394 874]);
                    result = [result struct('IDX', 2,'name', 'Frontal_Right_2', 'coords', [593 400 874])];
                    result = [result struct('IDX', 3,'name', 'Frontal_Left_2', 'coords', [473 394 874])];
                    result = [result struct('IDX', 4,'name', 'Anterior_Commissure_Right', 'coords', [606 535 793])];
                    result = [result struct('IDX', 5,'name', 'Anterior_Commissure_Left', 'coords', [461 532 794])];
                    result = [result struct('IDX', 7,'name', 'Corpus_Callosum_Middle', 'coords', [534 291 709])];
                    result = [result struct('IDX', 8,'name', 'Hippocampus_Middle', 'coords', [530 262 579])];
                    result = [result struct('IDX', 9,'name', 'Interpeduncular_Nucleus_Right', 'coords', [571 530 483])];
                    result = [result struct('IDX', 10,'name', 'Interpeduncular_Nucleus_Middle', 'coords', [533 532 483])];
                    result = [result struct('IDX', 11,'name', 'Interpeduncular_Nucleus_Left', 'coords', [494 532 483])];
                    
                case 'MV_Ntsr1_165'
                    result =  struct('IDX', 1,'name', 'Frontal_Middle_1', 'coords', [564 364 893]);                    
                    result = [result struct('IDX', 2,'name', 'Frontal_Right_2', 'coords', [622 352 893])];                    
                    result = [result struct('IDX', 3,'name', 'Frontal_Left_2', 'coords', [504 352 893])];                    
                    result = [result struct('IDX', 4,'name', 'Anterior_Commissure_Right', 'coords', [638 500 801])];                    
                    result = [result struct('IDX', 5,'name', 'Anterior_Commissure_Left', 'coords', [489 499 801])];                    
                    result = [result struct('IDX', 7,'name', 'Corpus_Callosum_Middle', 'coords', [565 263 719])];                    
                    result = [result struct('IDX', 8,'name', 'Hippocampus_Middle', 'coords', [563 223 597])];                    
                    result = [result struct('IDX', 9,'name', 'Interpeduncular_Nucleus_Right', 'coords', [602 497 485])];
                    result = [result struct('IDX', 10,'name', 'Interpeduncular_Nucleus_Middle', 'coords', [562 498 485])];
                    result = [result struct('IDX', 11,'name', 'Interpeduncular_Nucleus_Left', 'coords', [521 499 485])];

                case 'CR_Syt6CreRfp_35'
                    result = struct('IDX', 1,'name', 'Frontal_Middle_1', 'coords', [534 405 780]);
                    result = [result struct('IDX', 2,'name', 'Frontal_Right_2', 'coords', [594 394 780])];
                    result = [result struct('IDX', 3,'name', 'Frontal_Left_2', 'coords', [474 394 780])];
                    result = [result struct('IDX', 4,'name', 'Anterior_Commissure_Right', 'coords', [620 537 723])];
                    result = [result struct('IDX', 5,'name', 'Anterior_Commissure_Left', 'coords', [453 541 723])];
                    result = [result struct('IDX', 7,'name', 'Corpus_Callosum_Middle', 'coords', [536 317 638])];
                    result = [result struct('IDX', 8,'name', 'Hippocampus_Middle', 'coords', [534 284 512])];
                    result = [result struct('IDX', 9,'name', 'Interpeduncular_Nucleus_Right', 'coords', [573 554 409])];
                    result = [result struct('IDX', 10,'name', 'Interpeduncular_Nucleus_Middle', 'coords', [534 555 409])];
                    result = [result struct('IDX', 11,'name', 'Interpeduncular_Nucleus_Left', 'coords', [490 554 409])];
                    
                case 'ER_Glt25d2Cre_9'
                    result = struct('IDX', 1,'name', 'Frontal_Middle_1', 'coords', [422 271 828]);
                    result = [result struct('IDX', 2,'name', 'Frontal_Right_2', 'coords', [477 259 828])];
                    result = [result struct('IDX', 3,'name', 'Frontal_Left_2', 'coords', [362 262 828])];
                    result = [result struct('IDX', 4,'name', 'Anterior_Commissure_Right', 'coords', [496 413 769])];
                    result = [result struct('IDX', 5,'name', 'Anterior_Commissure_Left', 'coords', [334 416 769])];
                    result = [result struct('IDX', 7,'name', 'Corpus_Callosum_Middle', 'coords', [418 192 692])];
                    result = [result struct('IDX', 8,'name', 'Hippocampus_Middle', 'coords', [416 161 579])];
                    result = [result struct('IDX', 9,'name', 'Interpeduncular_Nucleus_Right', 'coords', [462 422 464])];
                    result = [result struct('IDX', 10,'name', 'Interpeduncular_Nucleus_Middle', 'coords', [419 422 464])];
                    result = [result struct('IDX', 11,'name', 'Interpeduncular_Nucleus_Left', 'coords', [379 423 464])];
                    
                case 'MV131017_7'
                    result = struct('IDX', 1,'name', 'Frontal_Middle_1', 'coords', [546 383 847]);
                    result = [result struct('IDX', 2,'name', 'Frontal_Right_2', 'coords', [604 384 847])];
                    result = [result struct('IDX', 3,'name', 'Frontal_Left_2', 'coords', [485 385 847])];
                    result = [result struct('IDX', 4,'name', 'Anterior_Commissure_Right', 'coords', [624 525 774])];
                    result = [result struct('IDX', 5,'name', 'Anterior_Commissure_Left', 'coords', [470 525 774])];
                    result = [result struct('IDX', 7,'name', 'Corpus_Callosum_Middle', 'coords', [545 290 693])];
                    result = [result struct('IDX', 9,'name', 'Interpeduncular_Nucleus_Right', 'coords', [583 531 467])];
                    result = [result struct('IDX', 10,'name', 'Interpeduncular_Nucleus_Middle', 'coords', [547 535 467])];
                    result = [result struct('IDX', 11,'name', 'Interpeduncular_Nucleus_Left', 'coords', [508 534 467])];
                    
                case 'AB_Gad67_223'
                    result = struct('IDX', 1,'name', 'Frontal_Middle_1', 'coords', [527 354 745]);
                    result = [result struct('IDX', 2,'name', 'Frontal_Right_2', 'coords', [585 347 745])];
                    result = [result struct('IDX', 3,'name', 'Frontal_Left_2', 'coords', [469 349 745])];
                    result = [result struct('IDX', 4,'name', 'Anterior_Commissure_Right', 'coords', [600 504 661])];
                    result = [result struct('IDX', 5,'name', 'Anterior_Commissure_Left', 'coords', [449 501 661])];
                    result = [result struct('IDX', 7,'name', 'Corpus_Callosum_Middle', 'coords', [524 264 578])];
                    result = [result struct('IDX', 8,'name', 'Hippocampus_Middle', 'coords', [521 234 451])];
                    result = [result struct('IDX', 9,'name', 'Interpeduncular_Nucleus_Right', 'coords', [557 527 361])];
                    result = [result struct('IDX', 10,'name', 'Interpeduncular_Nucleus_Middle', 'coords', [518 529 361])];
                    result = [result struct('IDX', 11,'name', 'Interpeduncular_Nucleus_Left', 'coords', [479 525 361])];
                    
                otherwise
                    error(['Brain Name ' brainName 'has no stored point list']);
            end
        end
    end
end

