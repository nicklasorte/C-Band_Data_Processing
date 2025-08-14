function [cell_stats_rtca_data_spur]=interference_criteria_rtca_data_spur_rev1(app,cell_split_rtca_data_spur,data_folder,folder1,tf_stats_data_spur,tf_stats_plots_spur,mean_height_error_percentage,percentile_threshold,avg_height_percentage,percentile_foot_limit,time_window_cut)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Statstical Analysis of Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd(data_folder)  %%%%%%%%%%Go to the directory where the RTCA data is located.
pause(0.1); %%%Matlab needs this momentary pause for some reason when changing folders

%%%%%%%%%%%%%%%%%Derived Criteria Thresholds
bottom_percentile=(100-percentile_threshold)/2;
top_percentile=100-(100-percentile_threshold)/2;
interp_step=min([1,bottom_percentile]);
array_interp_cdf=0:interp_step:100;  %%%%%%%Make this variable;

%%%%%%%%Check for the cell_all_rtca_data.mat file
cell_stats_rtca_data_spur_filename=strcat('cell_stats_rtca_data_spur_',num2str(mean_height_error_percentage),'_',num2str(percentile_threshold),'_',num2str(avg_height_percentage),'.mat');
[tf_stats_rtca_spur_mat]=persistent_var_exist_with_corruption(app,cell_stats_rtca_data_spur_filename);

if tf_stats_data_spur==1
    tf_stats_rtca_spur_mat=0;
end

if tf_stats_plots_spur==1
    tf_stats_rtca_spur_mat=0;
end


%%%%%%%Check example:UC1:E:5000:3750 MHz



if tf_stats_rtca_spur_mat==0
    [num_data_rows,num_col]=size(cell_split_rtca_data_spur);
    cell_stats_rtca_data_spur=cell(num_data_rows,1);
    tic;
    for data_row_idx=1:1:num_data_rows
        cell_split_rtca_data_spur(data_row_idx,:)
        %%%%cell_split_rtca_data(data_row_idx,:)
        %%%%%1)Frequency, 2)Power Level, 3)"OFF" Data, 4)"ON" Data
        temp_row_altimeter_data=cell_split_rtca_data_spur{data_row_idx,end};
        
        %%%%%%Maybe find the number of frequencies (3) and split up the statstical processing based on each frequency.
        uni_freq=unique(cell2mat(temp_row_altimeter_data(:,1)));
        num_uni_freq=length(uni_freq);
        
        cell_freq_stats=cell(num_uni_freq,12);
            %%%1) Full Excel Name
            %%%2) Use Case
            %%%3) Altimeter
            %%%4) Altitude
            %%%5) Center Frequency
            %%%6) Criteria 1: Mean Height IntPwr
            %%%7) Criteria 2-1%: Percentile Height IntPwr
            %%%8) Criteria 2-99%: Percentile Height IntPwr
            %%%9) Criteria 3: NCD IntPwr
            %%%10) Full Criteria 1 Data: combo_array_mean_height
            %%%11) Full Criteria 2 Data
            %%%12) Full Criteria 3 Data
        for freq_idx=1:1:num_uni_freq
            uni_freq(freq_idx)
            temp_freq_row_idx=find(cell2mat(temp_row_altimeter_data(:,1))==uni_freq(freq_idx));
            temp_freq_split_data=temp_row_altimeter_data(temp_freq_row_idx,:);
            [num_int_pwr,~]=size(temp_freq_split_data);
            
% % % %             temp_correction_row_idx=find(band_stop_filter_correction(:,1)==uni_freq(freq_idx));
% % % %             band_filter_correction=band_stop_filter_correction(temp_correction_row_idx,2);
            
            array_mean_height=NaN(num_int_pwr,4); %%%%% 1) Frequency, 2) IntPwr, 3)Off, 4)On
            array_percentile=NaN(num_int_pwr,6); %%%%%% 1) Frequency, 2) IntPwr, 3)Off 1%, 4)Off 99%, 5)ON 1%, 6)On 99%
            array_tf_ncd=NaN(num_int_pwr,4); %%%%%%%%%% 1) Frequency, 2) IntPwr, 3)Off, 4)On
            for int_pwr_idx=1:1:num_int_pwr
                %%%%%%1)Excel time 2)height 3)CenterF 4)RFPwrDBM 5)RFState 6)NCD 7)Corrected Time in Seconds
                temp_off_data=temp_freq_split_data{int_pwr_idx,3};
                temp_on_data=temp_freq_split_data{int_pwr_idx,4};  
                
                temp_off_data(:,7)=temp_off_data(:,1); %%%%Need to add the corrected time back
                temp_on_data(:,7)=temp_on_data(:,1); %%%%Need to add the corrected time back
                
% % %                 %%%%%%%%%Need to correct power: temp_off_data, temp_on_data
% % %                 temp_on_data(:,4)=temp_on_data(:,4)+band_filter_correction;
% % %                 temp_off_data(:,4)=temp_off_data(:,4)+band_filter_correction;
                
                %%%%%%%The time constant used was 1.75 seconds from the beginning and end of the interference power OFF subinterval.
                [time1_cut_idx]=nearestpoint_app(app,time_window_cut,temp_off_data(:,end));
                [time2_cut_idx]=nearestpoint_app(app,max(temp_off_data(:,end))-time_window_cut,temp_off_data(:,end));
                temp_off_data=temp_off_data(time1_cut_idx:time2_cut_idx,:);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%1. Calculate the Mean Height
                array_mean_height(int_pwr_idx,1)=uni_freq(freq_idx);
                array_mean_height(int_pwr_idx,2)=temp_freq_split_data{int_pwr_idx,2};%%%+band_filter_correction;
                array_mean_height(int_pwr_idx,3)=mean(temp_off_data(:,2),'omitnan');
                array_mean_height(int_pwr_idx,4)=mean(temp_on_data(:,2),'omitnan');
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%2. Calculate the Percentile with an Empirical CDF
                %%%%%%%Interpolate the CDF because we don't have enough data
                %%%%%%%(which is something RTCA probably did not do)
                array_percentile(int_pwr_idx,1)=uni_freq(freq_idx);
                array_percentile(int_pwr_idx,2)=temp_freq_split_data{int_pwr_idx,2};%%%%+band_filter_correction;
                
                if ~isempty(temp_off_data(:,2))==1
                    [f_off,x_off]=ecdf(temp_off_data(:,2));
                    intepr_off_cdf=interp1(f_off*100,x_off,array_interp_cdf);
                    temp_off_ecdf=horzcat(array_interp_cdf',intepr_off_cdf');
                    %%%%%%Find the two Percentile 1% and 99% Height (which can be a variable)
                    [off_bottom_idx]=nearestpoint_app(app,bottom_percentile,temp_off_ecdf(:,1));
                    [off_top_idx]=nearestpoint_app(app,top_percentile,temp_off_ecdf(:,1));
                    %%%%temp_off_ecdf
                    %%%%temp_off_ecdf(off_bottom_idx,:)
                    %%%%temp_off_ecdf(off_top_idx,:)
                    array_percentile(int_pwr_idx,3)=temp_off_ecdf(off_bottom_idx,2);
                    array_percentile(int_pwr_idx,4)=temp_off_ecdf(off_top_idx,2);
                end
                
                if ~isempty(temp_on_data(:,2))==1
                    [f_on,x_on]=ecdf(temp_on_data(:,2));
                    intepr_on_cdf=interp1(f_on*100,x_on,array_interp_cdf);
                    temp_on_ecdf=horzcat(array_interp_cdf',intepr_on_cdf');
                    %%%%%%Find the two Percentile 1% and 99% Height (which can be a variable)
                    [on_bottom_idx]=nearestpoint_app(app,bottom_percentile,temp_on_ecdf(:,1));
                    [on_top_idx]=nearestpoint_app(app,top_percentile,temp_on_ecdf(:,1));
                    %%%%temp_on_ecdf
                    %%%%temp_on_ecdf(on_bottom_idx,:)
                    %%%%temp_on_ecdf(on_top_idx,:)
                    array_percentile(int_pwr_idx,5)=temp_on_ecdf(on_bottom_idx,2);
                    array_percentile(int_pwr_idx,6)=temp_on_ecdf(on_top_idx,2);
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%3. Check for the NCD Flag
                array_tf_ncd(int_pwr_idx,1)=uni_freq(freq_idx);
                array_tf_ncd(int_pwr_idx,2)=temp_freq_split_data{int_pwr_idx,2};%%%%+band_filter_correction;
                if ~isempty(temp_off_data)==1
                    array_tf_ncd(int_pwr_idx,3)=any(temp_off_data(:,6));
                end
                if ~isempty(temp_on_data)==1
                    array_tf_ncd(int_pwr_idx,4)=any(temp_on_data(:,6));
                end
                
                %%%%%%%Future Step: This is where we need to calculate the recovery time of the altimeter operation after an interference.
            end
                        
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Check the Processed Data at which point to determine if there is interference
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%1. Find the Mean Height error greater than 0.5% (which is a variable)
            %%%mean_height_error=(abs(array_mean_height(:,4)-array_mean_height(:,3))./array_mean_height(:,3))*100;  %%%Save this array
            mean_height_error=((array_mean_height(:,4)-array_mean_height(:,3))./array_mean_height(:,3))*100;  %%%Save this array
            
% % % % % % %             mean_height_error2=((array_mean_height(:,4)-array_mean_height(:,3))./array_mean_height(:,4))*100;  %%%Save this array
% % % % % % %             round(abs(horzcat(mean_height_error,mean_height_error2)),3)
            
            mean_height_idx=find(abs(mean_height_error)>mean_height_error_percentage,1,'first')-1; %%%Minus 1
            mean_height_tf_array=abs(mean_height_error)>mean_height_error_percentage;
            if mean_height_idx==0
                'Zero Index Error'
                mean_height_idx=1;
                %pause;
            end
            
            combo_array_mean_height=horzcat(array_mean_height,mean_height_error,mean_height_tf_array);  %%%%%%%%%Save This One
            cell_freq_stats{freq_idx,10}=combo_array_mean_height;
                        
% %             %%%%%%%%%%%%%%%%%%%%%%Mean Height Table
% %             tic;
% %             cd(folder1)
% %             pause(0.1)
% %             mean_height_stats_table=cell2table(num2cell(round(combo_array_mean_height,3)));
% %             mean_height_stats_table.Properties.VariableNames={'Frequency' 'Int_Pwr' 'Off_Mean' 'On_Mean' 'Percentage_Error' 'Too_Much_Error'}
% %             writetable(mean_height_stats_table,strcat(cell_split_rtca_data{data_row_idx,1},'_',num2str(uni_freq(freq_idx)),'MHz_MeanErrorCalculation.xlsx'));
% %             cd(data_folder)  %%%%%%%%%%Go to the directory where the RTCA data is located.
% %             pause(0.1); %%%Matlab needs this momentary pause for some reason when changing folders
% %             toc;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%2. Find the Percentile
            on_h1=array_percentile(:,5);
            on_h99=array_percentile(:,6);
            
            %%%%On-Off/Off
            array_1p=(array_mean_height(:,3)-(array_mean_height(:,3).*(avg_height_percentage/100)));  %%%%This is 
            array_99p=(array_mean_height(:,3)+(array_mean_height(:,3).*(avg_height_percentage/100)));
            
            %%%%%%%%%%This is how AVSI does it.
            h1_tf_array=on_h1<array_1p;
            h99_tf_array=on_h99>array_99p;
            percentage_on_h1_idx=find(on_h1<array_1p,1,'first')-1;  %%%Minus 1
            percentage_on_h99_idx=find(on_h99>array_99p,1,'first')-1;  %%%Minus 1
            
            %%%%%%%%%%Used for Graphing
            on_h1_percentage=(on_h1-array_mean_height(:,3))./array_mean_height(:,3)*100;
            on_h99_percentage=(on_h99-array_mean_height(:,3))./array_mean_height(:,3)*100;
            on_1p_h1_percentage=(array_1p-array_mean_height(:,3))./array_mean_height(:,3)*100;
            on_99p_h99_percentage=(array_99p-array_mean_height(:,3))./array_mean_height(:,3)*100;
            
            
            if percentage_on_h1_idx==0
                'Zero Index Error'
                percentage_on_h1_idx=1;
                %pause;
            end
            
            if percentage_on_h99_idx==0
                'Zero Index Error'
                percentage_on_h99_idx=1;
                %pause;
            end
            
            %%%%%%%This was never used: 1.5 foot limit
            % % %             foot_off_h1_idx=find(on_h1<(array_mean_height(:,3)-percentile_foot_limit),1,'first');
            % % %             foot_off_h99_idx=find(on_h99>(array_mean_height(:,3)+percentile_foot_limit),1,'first');
            % % %             merge_foot_idx=min(horzcat(foot_off_h1_idx,foot_off_h99_idx));
            
            merge_h199_idx=min(horzcat(percentage_on_h1_idx,percentage_on_h99_idx));
            combo_array_percentile_data=horzcat(array_percentile,array_1p,h1_tf_array,array_99p,h99_tf_array);
            cell_freq_stats{freq_idx,11}=combo_array_percentile_data;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%3. Find if there is a NCD Flag
            ncd_idx=find(array_tf_ncd(:,4)==1,1,'first')-1; %%%Minus 1
            cell_freq_stats{freq_idx,12}=array_tf_ncd;
            
            if ncd_idx==0
                'Zero Index Error'
                ncd_idx=1;
                %%pause;
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Save the Threshold Interference Levels for Each Criteria
            %%%1) Full Excel Name
            %%%2) Use Case
            %%%3) Altimeter
            %%%4) Altitude
            %%%5) Center Frequency
            %%%6) Criteria 1: Mean Height IntPwr
            %%%7) Criteria 2-1%: Percentile Height IntPwr
            %%%8) Criteria 2-99%: Percentile Height IntPwr
            %%%9) Criteria 3: NCD IntPwr
            %%%10) Full Criteria 1 Data: combo_array_mean_height
            %%%11) Full Criteria 2 Data: combo_array_percentile_data
            %%%12) Full Criteria 3 Data
            cell_freq_stats{freq_idx,1}=cell_split_rtca_data_spur{data_row_idx,1};
            cell_freq_stats{freq_idx,2}=cell_split_rtca_data_spur{data_row_idx,2};
            cell_freq_stats{freq_idx,3}=cell_split_rtca_data_spur{data_row_idx,3};
            cell_freq_stats{freq_idx,4}=cell_split_rtca_data_spur{data_row_idx,4};
            cell_freq_stats{freq_idx,5}=uni_freq(freq_idx);
            
            if ~isempty(mean_height_idx)==1
                cell_freq_stats{freq_idx,6}=array_mean_height(mean_height_idx,2);
            else
                cell_freq_stats{freq_idx,6}=NaN(1);
            end
            
            if ~isempty(percentage_on_h1_idx)==1
                cell_freq_stats{freq_idx,7}=array_percentile(percentage_on_h1_idx,2);
            else
                cell_freq_stats{freq_idx,7}=NaN(1);
            end
            
             if ~isempty(percentage_on_h99_idx)==1
                cell_freq_stats{freq_idx,8}=array_percentile(percentage_on_h99_idx,2);
            else
                cell_freq_stats{freq_idx,8}=NaN(1);
            end
            
            if ~isempty(ncd_idx)==1
                cell_freq_stats{freq_idx,9}=array_tf_ncd(ncd_idx,2);
            else
                cell_freq_stats{freq_idx,9}=NaN(1);
            end
            
            horzcat(min(vertcat(cell_freq_stats{freq_idx,[6:9]})),cell_freq_stats{freq_idx,[6:9]})
            
            if tf_stats_plots_spur==1
                close all;
                figure;
                hold on;
                if ~isempty(mean_height_idx)==1
                    h10=plot([array_mean_height(mean_height_idx,2),array_mean_height(mean_height_idx,2)],[-100,100],'-b','LineWidth',2);
                end
                if ~isempty(percentage_on_h1_idx)==1
                    h11=plot([array_mean_height(percentage_on_h1_idx,2),array_mean_height(percentage_on_h1_idx,2)],[-100,100],'-r','LineWidth',2);
                end
                if ~isempty(percentage_on_h99_idx)==1
                    h12=plot([array_mean_height(percentage_on_h99_idx,2),array_mean_height(percentage_on_h99_idx,2)],[-100,100],'-r','LineWidth',2);
                end
                if ~isempty(ncd_idx)==1
                    h13=plot([array_tf_ncd(ncd_idx,2),array_tf_ncd(ncd_idx,2)],[-100,100],'-g','LineWidth',2);
                end
                h2=plot(combo_array_mean_height(:,2),mean_height_error_percentage*ones(size(combo_array_mean_height(:,2))),':','Color',[0,102,204]/255,'LineWidth',2,'DisplayName','C1:Mean Height Error Limit');
                h14=plot(combo_array_mean_height(:,2),-1*mean_height_error_percentage*ones(size(combo_array_mean_height(:,2))),':','Color',[0,102,204]/255,'LineWidth',2,'DisplayName','C1:Mean Height Error Limit');
                h15=plot(combo_array_mean_height(:,2),avg_height_percentage*ones(size(combo_array_mean_height(:,2))),':','Color',[255,102,102]/255,'LineWidth',2,'DisplayName','C2:Percentile Error Limit');
                h5=plot(combo_array_mean_height(:,2),-1*avg_height_percentage*ones(size(combo_array_mean_height(:,2))),':','Color',[255,102,102]/255,'LineWidth',2,'DisplayName','C2:Percentile Error Limit');
                
                h1=plot(combo_array_mean_height(:,2),combo_array_mean_height(:,5),'-o','Color',[62,105,225]/255,'LineWidth',2,'DisplayName','C1:Mean Height Error [%]');
                h3=plot(combo_array_mean_height(:,2),on_h1_percentage,'-d','Color',[255,102,255]/255,'LineWidth',2,'DisplayName','C2:1st Percentile');
                h4=plot(combo_array_mean_height(:,2),on_h99_percentage,'-s','Color',[255,51,153]/255,'LineWidth',2,'DisplayName','C2:99th Percentile');
                legend([h1, h2, h3, h4,h5])
                grid on;
                ylabel('Height Error (%)')
                grid on;
                xlabel('Interference Power (dBm)')
                title(strcat(cell_split_rtca_data_spur{data_row_idx,1},'---Center Frequency:',num2str(uni_freq(freq_idx)),'MHz'))
                filename1=strcat('Mod2Int_',cell_split_rtca_data_spur{data_row_idx,1},'_',num2str(uni_freq(freq_idx)),'MHz.png');
                saveas(gcf,char(filename1))
                pause(0.1);
                axis([min(xlim),max(xlim),-3,3])
                filename1=strcat('Zoom_Mod2Int_',cell_split_rtca_data_spur{data_row_idx,1},'_',num2str(uni_freq(freq_idx)),'MHz.png');
                saveas(gcf,char(filename1))
                pause(0.1);
            end
        end
        cell_stats_rtca_data_spur{data_row_idx}=cell_freq_stats;
    end
    toc;
    
    
% % %     'Pause Before Save'
% % %     pause;
    
    %%%%%Save
    tic;
    retry_save=1;
    while(retry_save==1)
        try
            save(cell_stats_rtca_data_spur_filename,'cell_stats_rtca_data_spur')  
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
            load(cell_stats_rtca_data_spur_filename,'cell_stats_rtca_data_spur') 
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


% % 
% % num_rows=length(cell_stats_rtca_data_spur);
% % cut_cell_stats_rtca_data_spur=cell(num_rows,1);  %%%%%All three criteria, and then the minimum
% % 
% % for row_idx=1:1:num_rows
% %     temp_cell_data=cell_stats_rtca_data_spur{row_idx};
% %     cut_cell_stats_rtca_data_spur{row_idx,1}=horzcat(temp_cell_data(:,[1:9]),mat2cell(min(cell2mat(temp_cell_data(:,[6:9])),[],2),[1],[1]));
% % end
% % 
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Save to excel files
% % cell_array_stats_rtca_data_spur=vertcat(cut_cell_stats_rtca_data_spur{:});
% % 
% % 
% % %%%%%%%%%%%%%%%%%%%%%%Full Table
% % full_stats_table=cell2table(cell_array_stats_rtca_data_spur);
% % full_stats_table.Properties.VariableNames={'Excel_Name' 'Use_Case' 'Altimeter' 'Altitude' 'Frequency' 'Criteria_1_Mean' 'Criteria_2_1%' 'Criteria_2_99%' 'Criteria_3_NCD' 'Breakpoint'};
% % tic;
% % writetable(full_stats_table,strcat('Spurious_Full_Int_',num2str(mean_height_error_percentage),'_',num2str(percentile_threshold),'_',num2str(avg_height_percentage),'.xlsx'));
% % toc;


end