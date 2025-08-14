function [cell_spurrious_avsi_data]=load_spurious_avsi_data_rev1(app,avsi_spurrious_data,tf_import_spurious)


%%%%%%%%Check for the cell_all_rtca_data.mat file
cell_avsi_data_filename=strcat('cell_spurrious_avsi_data.mat');
[tf_avsi_spurrious_mat]=persistent_var_exist_with_corruption(app,cell_avsi_data_filename);

if tf_import_spurious==1
    tf_avsi_spurrious_mat=0;
end

if tf_avsi_spurrious_mat==0    
    tic;
    [~,sheet_name]=xlsfinfo(avsi_spurrious_data); 
    toc;
            
    tic;
    [~,~,raw1]=xlsread(avsi_spurrious_data,sheet_name{1});  %%%%%%%%Load in the first Sheet
    toc;
    
    header1_varname=raw1(1,:)';  %%%%%First Row in the Excel Data with the Headers
    length_header=length(header1_varname);
    for j=1:1:length_header  %%%%%%%Need to Replace 'NaN' in header
        if isnan(header1_varname{j})==1
            header1_varname{j}=strcat('NAN');
        end
    end
    number1_idx=find(contains(header1_varname,'#'));
    uc1_idx=find(contains(header1_varname,'UC'));
    eut1_idx=find(contains(header1_varname,'Altimeter'));
    alt_ft1_idx=find(contains(header1_varname,'Alt (ft)'));
    cf1_idx=find(contains(header1_varname,'CF'));
    bp1_idx=find(contains(header1_varname,'Break Point (dBm)'));
    criteria1_idx=find(contains(header1_varname,'Criterion'));
    
    %%%%%%Keep Same Order as Spread Sheet
    raw_spurrious_data_summary=raw1(2:end,[number1_idx,uc1_idx,eut1_idx,alt_ft1_idx,cf1_idx,bp1_idx,criteria1_idx]);
    
    tic;
    [num,~,raw2]=xlsread(avsi_spurrious_data,sheet_name{2});  %%%%%%%%Load in the data
    toc;
    
    header_varname2=raw2(3,:)';  %%%%%First Row in the Excel Data with the Headers
    length_header=length(header_varname2);
    for j=1:1:length_header  %%%%%%%Need to Replace 'NaN' in header
        if isnan(header_varname2{j})==1
            header_varname2{j}=strcat('NAN');
        end
    end
    
    header_varname2
    
    num2_idx=find(contains(header_varname2,'#'));
    uc2_idx=find(contains(header_varname2,'UC'));
    eut2_idx=find(contains(header_varname2,'Altimeter'));
    alt_ft2_idx=find(contains(header_varname2,'Alt (ft)'));
    cf2_idx=find(contains(header_varname2,'CF'));
    bp2_idx=find(contains(header_varname2,'Break Point'));
    nbp2_idx=find(contains(header_varname2,'No Break'));
    mean_idx=find(contains(header_varname2,'Mean Error'));
    cdf1_idx=find(contains(header_varname2,'1% ht < -2% err'));
    cdf99_idx=find(contains(header_varname2,'99% ht > +2% err'));
    ncd2_idx=find(contains(header_varname2,'NCD'));
    tf_eng_idx=find(contains(header_varname2,'tf_engineer'));
    
    
    raw_spurrious_data_expanded=raw2(4:end-1,[num2_idx,uc2_idx,eut2_idx,alt_ft2_idx,cf2_idx,bp2_idx,nbp2_idx,mean_idx,cdf1_idx,cdf99_idx,ncd2_idx,tf_eng_idx]);
   [x1,y1]=size(raw_spurrious_data_expanded);
   for i=1:1:x1  %%%%%%%Need to Replace 'NaN'
       for j=1:1:y1
           if isnan(raw_spurrious_data_expanded{i,j})==1
               raw_spurrious_data_expanded{i,j}=strcat('NAN');
           end
       end
   end
   
   cell_spurrious_avsi_data=cell(2,1);
   cell_spurrious_avsi_data{1}=raw_spurrious_data_summary;
   cell_spurrious_avsi_data{2}=raw_spurrious_data_expanded;
   

    %%%%%Save
    tic;
    retry_save=1;
    while(retry_save==1)
        try
            save(cell_avsi_data_filename,'cell_spurrious_avsi_data') 
            pause(0.1);
            retry_save=0;
        catch
            retry_save=1;
            pause(0.1)
        end
    end
    toc;  %%%%%%2-3 seconds
else
    %%%%%Load
    %tic;
    retry_load=1;
    while(retry_load==1)
        try
            load(cell_avsi_data_filename,'cell_spurrious_avsi_data')  
            pause(0.1);
            retry_load=0;
        catch
            retry_load=1;
            pause(0.1)
        end
    end
    %toc;
end





