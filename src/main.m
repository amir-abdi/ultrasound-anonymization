clear all; clc;

%set parameters
flag_showImages = true;
flag_writeDicom = false;
flag_writeMatlab = true;
starting_folder_index = 1;
starting_file_index = 1;
dataset_name = 'EF_Estimation_509cases_2017.5.10\';
src_folder = 'L:\Final4class_since2011_round3';
dst_folder = ['Z:\' dataset_name];
csvSummaryFile = 'DataSummary.csv';

%Fields that are kept in the anonymized DICOM. 
KeepsFields = {'PatientID',...
    'StudyDate', 'SeriesDate', 'AcquisitionDateTime', ...
    'StudyInstanceUID','SOPInstanceUID', 'SOPClassUID',...
    'Manufacturer','ManufacturerModelName', 'TransducerData',...
    'SequenceOfUltrasoundRegions',...
    'Width', 'Height', 'BitDepth', 'FrameTime', 'HeartRate', 'NumberOfFrames'
    };

%%
dir_dates = dir(src_folder);
dirFlags = [dir_dates.isdir];
dir_dates = dir_dates(dirFlags);
dir_dates = dir_dates(3:end);

if ~exist(dst_folder)
    mkdir(dst_folder)
end

%create main folders
mat_anon_dir = [dst_folder 'MatAnon\'];
dcm_anon_dir = [dst_folder 'DcmAnon\'];
if flag_writeMatlab && ~exist(mat_anon_dir)
    mkdir(mat_anon_dir);
end
if flag_writeDicom && ~exist(dcm_anon_dir)
    mkdir(dcm_anon_dir);
end

%% Creates a CSV that stores all fields except SequenceOfUltrasoundRegions
if ~exist([dst_folder csvSummaryFile])
    csvFile = fopen([dst_folder csvSummaryFile], 'w');
    fprintf(csvFile, '%s', KeepsFields{1});    
    for dVal = 2 : numel(KeepsFields)                
        fprintf(csvFile, ',%s', KeepsFields{dVal});                
    end
    fprintf(csvFile, ',filename\n');
else
    csvFile = fopen([dst_folder csvSummaryFile], 'a');
end

%%
for ix = starting_folder_index : numel(dir_dates)
    disp(ix);
    studies_root = [src_folder,'\',dir_dates(ix).name];
    dir_studies = dir(studies_root);
    dir_studies = dir_studies (3:end);
    mkdir(mat_anon_dir,dir_dates(ix).name);
    mkdir(dcm_anon_dir,dir_dates(ix).name);

    for kx = starting_file_index : numel(dir_studies)
        tic;
        patFile = [studies_root,'\',dir_studies(kx).name];

        %Try to read file
        try
            patDicomInfo = dicominfo(patFile);                        

            patDicomImage = dicomread(patFile);
            
            anonymized_name= [dir_dates(ix).name,'\', num2str(kx,'%03d'), '_',  patDicomInfo.SOPInstanceUID];
            
            machineType = patDicomInfo.ManufacturerModelName;
            manufacturer = patDicomInfo.Manufacturer;
            Patient.DicomImage = maskPatientInfo(patDicomImage, machineType, manufacturer);
            
            if flag_showImages
                imshow(Patient.DicomImage(:,:,:,1));
            end
            
            Patient.DicomInfo = [];
            for dVal = 1 : numel(KeepsFields)
                if isfield(patDicomInfo,KeepsFields{dVal})
                    Patient.DicomInfo.(KeepsFields{dVal}) = patDicomInfo.(KeepsFields{dVal});                                    
                end
            end
            Patient.OriginalFileName = dir_studies(kx).name;
            
            if flag_writeMatlab
                matlabfileName = [mat_anon_dir, anonymized_name '.mat'];
                save(matlabfileName, 'Patient');                                        
                disp([num2str(ix) ':' num2str(kx) '   File saved: ' matlabfileName]);
            end
            if flag_writeDicom
                dicomFileName = [dcm_anon_dir, anonymized_name, '.dcm']
                dicomwrite(Patient.DicomImage, dicomFileName, Patient.DicomInfo, 'CreateMode','copy');           
                disp([num2str(ix) ':' num2str(kx) '   File saved: ' matlabfileName]);
            end
            
            fprintf(csvFile, '%s', patDicomInfo.(KeepsFields{1}));
            for dVal = 2 : numel(KeepsFields)
                if isfield(patDicomInfo,KeepsFields{dVal}) && isstruct(patDicomInfo.(KeepsFields{dVal})) == 0
                      if ischar(patDicomInfo.(KeepsFields{dVal}))                    
                        fprintf(csvFile, ',%s', patDicomInfo.(KeepsFields{dVal}));
                      else
                          fprintf(csvFile, ',%s', num2str(patDicomInfo.(KeepsFields{dVal})));
                      end
                else
                      fprintf(csvFile, ',%s', '');
                end
            end
            
            fprintf(csvFile, ',%s\n', dir_studies(kx).name);
            
            
        catch err
            disp([num2str(ix) ':' num2str(kx) '    Did not Save']);    
            disp(err);
            if ~isempty(findstr('[NotCoded]', err.message))                
                disp('Asserting as there might be a new manufacturer/model');
                imshow(patDicomImage(:,:,:,1));
                assert(false, err.message);
            else
                disp(err.message);
                continue
            end            
        end

    end
end


%%
fclose(csvFile);

disp('Done');

