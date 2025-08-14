function [cell_split_rtca_data_spur]=split_spur_rtca_data_rev1(app,cell_all_rtca_data_spur,data_folder,folder1,tf_resplit_data,tf_recreate_excel_plots)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Split Data (Break into Frequency and Interference Power)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd(data_folder)  %%%%%%%%%%Go to the directory where the RTCA data is located.
pause(0.1); %%%Matlab needs this momentary pause for some reason when changing folders

%%%%%%%%Check for the cell_all_rtca_data.mat file
cell_split_rtca_data_filename=strcat('cell_split_rtca_data_spur.mat');
[tf_split_rtca_mat]=persistent_var_exist_with_corruption(app,cell_split_rtca_data_filename);

if tf_resplit_data==1
    tf_split_rtca_mat=0;
end

if tf_recreate_excel_plots==1
    tf_split_rtca_mat=0;
end

if tf_split_rtca_mat==0
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%1)Excel time 2)height 3)CenterF 4)RFPwrDBM 5)RFState 6)NCD 7)Corrected Time in Seconds
    [num_data_rows,num_col]=size(cell_all_rtca_data_spur);
    cell_split_rtca_data_spur=cell(num_data_rows,5);  %%%%%The split data nested cell
    array_time_diff=NaN(num_data_rows,3);
    for data_row_idx=1:1:num_data_rows
        data_row_idx/num_data_rows*100
        cell_split_rtca_data_spur{data_row_idx,1}=cell_all_rtca_data_spur{data_row_idx,1};
        cell_split_rtca_data_spur{data_row_idx,2}=cell_all_rtca_data_spur{data_row_idx,2};
        cell_split_rtca_data_spur{data_row_idx,3}=cell_all_rtca_data_spur{data_row_idx,3};
        cell_split_rtca_data_spur{data_row_idx,4}=cell_all_rtca_data_spur{data_row_idx,4};
        %%%cell_split_rtca_data{data_row_idx,5}=cell_all_rtca_data_spur{data_row_idx,5}; %%%%%%%%%We don't need to pull the raw data through
        
        
        %%%%%First break into frequency
        temp_full_data=cell_all_rtca_data_spur{data_row_idx,5};
        uni_freq=unique(temp_full_data(:,3));
        num_uni_freq=length(uni_freq);
        
        cell_data_freq_split=cell(num_uni_freq,1);
        for freq_idx=1:1:num_uni_freq
            temp_freq_row_idx=find(temp_full_data(:,3)==uni_freq(freq_idx));
            clear temp_freq_split_data;
            temp_freq_split_data=temp_full_data(temp_freq_row_idx,:);
% %             temp_time_array=temp_freq_split_data(:,1)-temp_freq_split_data(1,1);
% %             excel_time_factor=(659.647998679429)/0.007636851900315380;  %%%%%%%%%%%%%%%%%This was found the hard way and may not be right. 
% %             cor_time_array=temp_time_array*excel_time_factor;
% %             temp_freq_split_data(:,end+1)=cor_time_array; %%%%We add the time in seconds at the end

            if tf_recreate_excel_plots==1
                %%%%%%%%%%Rough RTCA Excel Plot Recreation for a Single Frequency
                close all;
                figure;
                hold on;
                yyaxis left
                plot(temp_freq_split_data(:,1),temp_freq_split_data(:,2),'-r')
                ylabel('Reported Height (ft)')
                yyaxis right
                int_pwr_on_idx=find(temp_freq_split_data(:,5)==1);
                plot(temp_freq_split_data(int_pwr_on_idx,1),temp_freq_split_data(int_pwr_on_idx,4),'ob')
                ylabel('Interference Power (dBm)')
                grid on;
                xlabel('Elapsed Second (Seconds)')
                title(strcat(cell_all_rtca_data_spur{data_row_idx,1},'---Center Frequency:',num2str(uni_freq(freq_idx)),'MHz'))
                filename1=strcat(cell_all_rtca_data_spur{data_row_idx,1},'_',num2str(uni_freq(freq_idx)),'MHz.png');
                saveas(gcf,char(filename1))
                pause(0.1);
            end
            
            %%%%%%Break Into Interference Power
            [uni_int_pwr,ia_idx,~]=unique(temp_freq_split_data(:,4));
            uni_int_pwr=uni_int_pwr(~isnan(uni_int_pwr));
            min_off_pwr=min(uni_int_pwr);
            uni_int_pwr(1)=[]; %%%%%%Cut the Min power
            num_uni_int_pwr=length(uni_int_pwr);
            
% %             %%%%%%Power is off in the G altimeter:
% %             if contains(cell_split_rtca_data{data_row_idx,3},'G')==1
% %                 %'The "G" altimeter data is a bit off when reporting interference power'
% %                 num_uni_int_pwr=num_uni_int_pwr+1;
% %                 uni_int_pwr(end+1)=uni_int_pwr(end)+1;
% %             end
            
            %%%%%%%%%%Check for NaN int_pwr, this fixes 'UC1B200'
            if any(isnan(temp_freq_split_data(:,4)))
                %'NaN in the int_pwr'
                %'Replace the NaN with a the max int_pwr + 1'
                
                nan_idx=find(isnan(temp_freq_split_data(:,4)));
                temp_freq_split_data(nan_idx,4)=uni_int_pwr(end)+1;
                [uni_int_pwr,ia_idx,~]=unique(temp_freq_split_data(:,4));
                uni_int_pwr=uni_int_pwr(~isnan(uni_int_pwr));
                num_uni_int_pwr=length(uni_int_pwr);
            end
            
            
            temp_cell_int_pwr=cell(num_uni_int_pwr,4);  %%%%%1)Frequency, 2)Power Level, 3)"OFF" Data, 4)"ON" Data
            last_cut_idx=0;
            new_cut_idx=1;
            for j=1:1:num_uni_int_pwr
                %%%%%%horzcat(j,last_cut_idx,new_cut_idx)
                if j==num_uni_int_pwr
                    first_temp_int_row_idx=1:1:length(temp_freq_split_data);
                     first_cut=temp_freq_split_data(first_temp_int_row_idx,:);
                    new_cut_idx=find(first_cut(:,5)==1,1,'last');
                    temp_int_row_idx=last_cut_idx+1:1:new_cut_idx;
                else
                    %%%%%%%%Need to find the last "ON"
                    first_temp_int_row_idx=1:1:ia_idx(j+2)-1;
                    first_cut=temp_freq_split_data(first_temp_int_row_idx,:);
                    new_cut_idx=find(first_cut(:,5)==1,1,'last');
                    temp_int_row_idx=last_cut_idx+1:1:new_cut_idx;
                end
                %clc;
                %temp_g_data=temp_freq_split_data(temp_int_row_idx,:)
                %horzcat(min(temp_int_row_idx),max(temp_int_row_idx))
                %horzcat(j,last_cut_idx,new_cut_idx)
                last_cut_idx=new_cut_idx;
                
                temp_int_pwr_split_data=temp_freq_split_data(temp_int_row_idx,:);
                temp_min_pwr_idx=find(temp_int_pwr_split_data(:,4)==min_off_pwr);
                temp_int_pwr_split_data(temp_min_pwr_idx,4)=uni_int_pwr(j);
% %                 temp_int_pwr_split_data
% %                 j
% %                 uni_int_pwr(j)
% %                 if j==num_uni_int_pwr
% %                     pause;
% %                 end
                
                
                %%%%%%Split Between On/Off
                temp_cell_int_pwr{j,1}=uni_freq(freq_idx);
                temp_cell_int_pwr{j,2}=uni_int_pwr(j);

                
                int_pwr_off_idx=find(temp_int_pwr_split_data(:,5)==0);
                temp_cell_int_pwr{j,3}=temp_int_pwr_split_data(int_pwr_off_idx,:);
                
                int_pwr_on_idx=find(temp_int_pwr_split_data(:,5)==1);
                temp_cell_int_pwr{j,4}=temp_int_pwr_split_data(int_pwr_on_idx,:);
            end
            cell_data_freq_split{freq_idx}=temp_cell_int_pwr;
        end
        cell_data_freq_split
        expand_cell_data_freq_split=vertcat(cell_data_freq_split{:});
        expand_cell_data_freq_split
        cell_split_rtca_data_spur{data_row_idx,5}=expand_cell_data_freq_split;
         
    end
    %%%%%Save
    tic;
    retry_save=1;
    while(retry_save==1)
        try
            save(cell_split_rtca_data_filename,'cell_split_rtca_data_spur')  %%%%%%%%About 25MB?
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
    tic;
    retry_load=1;
    while(retry_load==1)
        try
            load(cell_split_rtca_data_filename,'cell_split_rtca_data_spur')  %%%%%%%%About 25MB?
            pause(0.1);
            retry_load=0;
        catch
            retry_load=1;
            pause(0.1)
        end
    end
    toc;
end
cd(folder1)
pause(0.1);

end
 