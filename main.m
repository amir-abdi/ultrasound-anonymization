clear all; clc;

%set parameters
flag_showImages = true;
flag_writeDicom = false;
flag_writeMatlab = true;
starting_folder_index = 73;
starting_file_index = 1;
dataset_name = '';
src_folder = 'directory_holding_study_folders\';
dst_folder = 'directory_to_write_the_anonymized_records\';
csvSummaryFile = 'DataSummary.csv';

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

%%
%Fields that are kept in the anonymized DICOM. 
KeepsFields = {'PatientID',...
    'StudyDate', 'SeriesDate', 'AcquisitionDateTime', ...
    'StudyInstanceUID','SOPInstanceUID', 'SOPClassUID',...
    'Manufacturer','ManufacturerModelName', 'TransducerData',...
    'SequenceOfUltrasoundRegions',...
    'Width', 'Height', 'BitDepth', 'FrameTime', 'HeartRate', 'NumberOfFrames'
    };


%Creates a CSV that stores all fields except SequenceOfUltrasoundRegions
csvFile = fopen([dst_folder csvSummaryFile], 'w');
fprintf(csvFile, '%s', KeepsFields{1});
for dVal = 2 : numel(KeepsFields)                
    fprintf(csvFile, ',%s', KeepsFields{dVal});                
end
fprintf(csvFile, ',filename\n');

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
            
            
            
        catch err
            disp('Did not Save');    
            disp(err);
            if ~isempty(findstr('[NotCoded]', err.message))                
                disp('Asserting as there might be a new manufacturer/model');
                imshow(Patient.DicomImage(:,:,:,1));
                assert(false, err.message);
            end            
        end

    end
end


%%
fclose(csvFile);



