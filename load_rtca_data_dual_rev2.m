function [cell_all_rtca_data]=load_rtca_data_dual_rev2(app,data_folder,folder1,tf_reimport_data)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Load the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd(data_folder)  %%%%%%%%%%Go to the directory where the RTCA data is located.
pause(0.1); %%%Matlab needs this momentary pause for some reason when changing folders

%%%%%%%%Check for the cell_all_rtca_data.mat file
cell_all_rtca_data_filename=strcat('cell_all_rtca_data.mat');
[tf_all_rtca_mat]=persistent_var_exist_with_corruption(app,cell_all_rtca_data_filename);

if tf_reimport_data==1
    tf_all_rtca_mat=0;
end

if tf_all_rtca_mat==0
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Find the Files to Load
    list_excel_filenames=dir(data_folder); %%%%%Find the name of the data files
    cell_full_filenames=struct2cell(list_excel_filenames)';
    cell_full_filenames=cell_full_filenames(:,1);
    xlsx_idx=find(contains(cell_full_filenames,'.xlsx')==1); %%%Find the files with the name "UC . . . ."
    cell_xlsx_filenames=cell_full_filenames(xlsx_idx,1)  %%%These are the filename we want to load.
    num_file=length(cell_xlsx_filenames);
    
    %%%%%%%%Split and Create 4 Dimensional Cell
    cell_all_rtca_data=cell(num_file,8);  %%%%%% 1) Full Name, 2) Use Case, 3) Altimeter, 4) Altitude 5)Data (Full Raw), 6)3750MHz 7)3850MHz 8)3930MHz
    cell_uc_name=cell(num_file,1);
    for i=1:1:num_file
        temp_cut=strsplit(cell_xlsx_filenames{i},'.xlsx'); %%%%%First cut off the excel filename
        temp_str=temp_cut{1};
        cell_all_rtca_data{i,1}=temp_str;
        cell_all_rtca_data{i,2}=str2num(temp_str(3));
        cell_all_rtca_data{i,3}=temp_str(4);
        cell_all_rtca_data{i,4}=str2num(temp_str(5:end));
    end
    
    for i=1:1:num_file
        i/num_file*100
        cell_xlsx_filenames{i}
        
        %%%%%%%%Check for the individual mat file
        single_mat_filename=strcat(cell_all_rtca_data{i,1},'_array_rtca_data.mat');
        [tf_single_rtca_mat]=persistent_var_exist_with_corruption(app,single_mat_filename);
        
        if tf_reimport_data==1
            tf_single_rtca_mat=0;
        end
        
        %%%%%%%%Check for the individual mat file
        single_cell_filename=strcat(cell_all_rtca_data{i,1},'_single_cell_rtca_data.mat');
        [tf_single_rtca_cell]=persistent_var_exist_with_corruption(app,single_cell_filename);
        
        if tf_reimport_data==1
            tf_single_rtca_cell=0;
        end

        if tf_single_rtca_mat==0 || tf_single_rtca_cell==0
            
            tic;
            [~,sheet_name]=xlsfinfo(cell_xlsx_filenames{i}); %%%%%%Find the sheet names in the excel file
            sheet_idx=find(contains(sheet_name,cell_all_rtca_data{i,1})==1); %%%Find the excel sheet with the data
            toc;
            
            if isempty(sheet_idx)==1
                strcat('We have problem with Excel sheet:',cell_xlsx_filenames{i})
                pause;
            end
            
            tic;
            [num,~,raw]=xlsread(cell_xlsx_filenames{i},sheet_name{sheet_idx});  %%%%%%%%Load in the data
            toc;
            
            header_varname=raw(1,:)'  %%%%%First Row in the Excel Data with the Headers
            length_header=length(header_varname);
            for j=1:1:length_header  %%%%%%%Need to Replace 'NaN' in header
                if isnan(header_varname{j})==1
                    header_varname{j}=strcat('NAN');
                end
            end
            
            time_idx=find(contains(header_varname,'time'));
            height_idx=find(contains(header_varname,'height'));
            center_freq_idx=find(contains(header_varname,'CenterF'));
            pwr_idx=find(contains(header_varname,'RFPwrDBM'));
            state_idx=find(contains(header_varname,'RFState'));
            ncd_idx=find(contains(header_varname,'NCD'));
            
            
            
            %%%%%%Keep Same Order as Spread Sheet
            temp_data_time=cell2mat(raw(2:end,time_idx));
            temp_data_time=temp_data_time(~isnan(temp_data_time));
            temp_data_height=cell2mat(raw(2:end,height_idx));
            temp_data_height=temp_data_height(~isnan(temp_data_height));
            temp_data_center_freq=cell2mat(raw(2:end,center_freq_idx));
            temp_data_center_freq=temp_data_center_freq(~isnan(temp_data_center_freq));
            temp_data_pwr=cell2mat(raw(2:end,pwr_idx));
            % % % %         %nan_idx=find(isnan(temp_data_pwr))
            % % % %         %temp_data_pwr=temp_data_pwr(~isnan(temp_data_pwr)); %%%%%%Disabled because there was some data with "blanks" in the power, but the power was off
            
            temp_cell_state=raw(2:end,state_idx);
            temp_length_state=length(temp_cell_state);
            on_idx=find(contains(temp_cell_state,'ON'));
            off_idx=find(contains(temp_cell_state,'OFF'));
            temp_data_state=NaN(temp_length_state,1);
            temp_data_state(on_idx)=1;
            temp_data_state(off_idx)=0;
            
            temp_cell_ncd=raw(2:end,ncd_idx);
            temp_length_ncd=length(temp_cell_ncd);
            yes_idx=find(contains(temp_cell_ncd,'Y'));
            no_idx=find(contains(temp_cell_ncd,'N'));
            temp_data_ncd=NaN(temp_length_ncd,1);
            temp_data_ncd(yes_idx)=1;
            temp_data_ncd(no_idx)=0;
            
            horzcat(length(temp_data_time),length(temp_data_height),length(temp_data_center_freq),length(temp_data_pwr),length(temp_data_state),length(temp_data_ncd))%%%%%%Checking Size of Each Data Element
            array_rtca_data=horzcat(temp_data_time,temp_data_height,temp_data_center_freq,temp_data_pwr,temp_data_state,temp_data_ncd);
            
            
            %%%%%%%%%%%%%%%%%%%%%%%Second Pull of Data
            elapsed_idx=find(contains(header_varname,'Elapsed Time'));
            height3750_idx=find(contains(header_varname,'Height(3750)'));
            height3850_idx=find(contains(header_varname,'Height(3850)'));
            height3930_idx=find(contains(header_varname,'Height(3930)'));
            int_pwr3_idx=find(contains(header_varname,'Int Pwr'));
            
            if length(elapsed_idx)~=3
                'Error elapsed_idx:'
                elapsed_idx
            end
            
            
            if length(int_pwr3_idx)~=3
                'Error int_pwr3_idx:'
                int_pwr3_idx
            end
            
            %%%%%%%%%%%%%Slightly Processed Data By AVSI (Time Stamp)
            temp_data_3750=cell2mat(raw(2:end,horzcat(elapsed_idx(1),height3750_idx,int_pwr3_idx(1))));
            temp_data_3750=temp_data_3750(~isnan(temp_data_3750(:,1)),:);
            temp_data_3750(end,:)=[];  %%%%Remove the last point because these usually have errors.
            
            
            temp_data_3850=cell2mat(raw(2:end,horzcat(elapsed_idx(2),height3850_idx,int_pwr3_idx(2))));
            temp_data_3850=temp_data_3850(~isnan(temp_data_3850(:,1)),:);
            temp_data_3850(end,:)=[];  %%%%Remove the last point because these usually have errors.
            
            
            temp_data_3930=cell2mat(raw(2:end,horzcat(elapsed_idx(3),height3930_idx,int_pwr3_idx(3))));
            temp_data_3930=temp_data_3930(~isnan(temp_data_3930(:,1)),:);
            temp_data_3930(end,:)=[];  %%%%Remove the last point because these usually have errors.
            
            single_cell_rtca_data=cell(3,1); %%%%%%1)3750MHz 2) 3850MHz 3) 3930MHz
            single_cell_rtca_data{1}=temp_data_3750;
            single_cell_rtca_data{2}=temp_data_3850;
            single_cell_rtca_data{3}=temp_data_3930;
            
            %%%%%Save
            retry_save=1;
            while(retry_save==1)
                try
                    save(single_mat_filename,'array_rtca_data')
                    save(single_cell_filename,'single_cell_rtca_data')
                    pause(0.1);
                    retry_save=0;
                catch
                    retry_save=1;
                    pause(0.1)
                end
            end
        else
            %%%%%Load
            retry_load=1;
            while(retry_load==1)
                try
                    load(single_mat_filename,'array_rtca_data')
                    load(single_cell_filename,'single_cell_rtca_data')
                    pause(0.1);
                    retry_load=0;
                catch
                    retry_load=1;
                    pause(0.1)
                end
            end
        end
        
        %%%%%%%%%%%Stich all the data together 
        cell_all_rtca_data{i,5}=array_rtca_data;
        cell_all_rtca_data{i,6}=single_cell_rtca_data{1};
        cell_all_rtca_data{i,7}=single_cell_rtca_data{2};
        cell_all_rtca_data{i,8}=single_cell_rtca_data{3};
    end
    %%%%%Save
    tic;
    retry_save=1;
    while(retry_save==1)
        try
            save(cell_all_rtca_data_filename,'cell_all_rtca_data')  %%%%%%%%About 7MB?
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
            load(cell_all_rtca_data_filename,'cell_all_rtca_data')  %%%%%%%%About 7MB?
            pause(0.1);
            retry_load=0;
        catch
            retry_load=1;
            pause(0.1)
        end
    end
    %toc;
end

 cd(folder1)
 pause(0.1); 






end