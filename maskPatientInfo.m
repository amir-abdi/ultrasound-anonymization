%Each manufacturer and machine has its own labeling schema and need to be
%dealt with in a case-by-case fashion.
function patDicomImage = maskPatientInfo(patDicomImage, machine, manuf)
message = ['[NotCoded] ' manuf ' : ' machine];
if strcmp(manuf,'Philips Medical Systems')
    if strcmp(machine,'iE33')                                     
        patDicomImage(1:round(size(patDicomImage,1)*1/10),:,:) = 0;        
    elseif (strcmp(machine,'SONOS'))
        patDicomImage(1:round(size(patDicomImage,1)*0.4),...
                  1:round(size(patDicomImage,2)*1.2/5),:) = 0;             
    elseif strcmp(machine, 'CX50')
        patDicomImage(1:round(size(patDicomImage,1)*1/10),:,:) = 0;        
    elseif (strcmp(machine,'QLAB'))
        assert(false, message);
    else        
        assert(false, message);
    end
elseif ((strcmp(manuf,'GE Healthcare') || strcmp(manuf,'GE Vingmed Ultrasound') || strcmp(manuf,'GEMS Ultrasound')))
    if strcmp(machine,'Vivid i')
        patDicomImage(1:round(size(patDicomImage,1)*0.061),...
                  1:round(size(patDicomImage,2)*2/5),:) = 0;
    elseif (strcmp(machine,'Vivid E9'))
        patDicomImage(1:round(size(patDicomImage,1) *1/9.5),:,:) = 0;    
    elseif (strcmp(machine,'EchoPAC PC') || strcmp(machine,'Vivid7')) 
        % 'Vivid7' is basically like 'Vivid i', but there was one sample
        % which was like 'EchoPAC PC' and I had to be conservative.
        patDicomImage(1:round(size(patDicomImage,1) *2/5),...
                      1:1:round(size(patDicomImage,2) * 1.2/5),:) = 0;    
    else       
        assert(false, message);
    end
elseif strcmp(manuf,'ACUSON') && strcmp(machine,'SEQUOIA') 
    patDicomImage(1:round(size(patDicomImage,1)*0.061),...
                  1:round(size(patDicomImage,2)*2/5),:) = 0;  
else    
    assert(false, message);
end

return;