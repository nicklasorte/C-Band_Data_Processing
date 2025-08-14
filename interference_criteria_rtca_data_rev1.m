function [cell_stats_rtca_data]=interference_criteria_rtca_data_rev1(app,cell_split_rtca_data,data_folder,folder1,tf_stats_data,tf_stats_plots,mean_height_error_percentage,percentile_threshold,avg_height_percentage,percentile_foot_limit)

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
cell_stats_rtca_data_filename=strcat('cell_stats_rtca_data.mat');
[tf_stats_rtca_mat]=persistent_var_exist_with_corruption(app,cell_stats_rtca_data_filename);

if tf_stats_data==1
    tf_stats_rtca_mat=0;
end

if tf_stats_plots==1
    tf_stats_rtca_mat=0;
end

if tf_stats_rtca_mat==0
    [num_data_rows,num_col]=size(cell_split_rtca_data);
    cell_stats_rtca_data=cell(num_data_rows,1);
    tic;
    for data_row_idx=1:1:num_data_rows
        
        %%%%cell_split_rtca_data(data_row_idx,:)
        %%%%%1)Frequency, 2)Power Level, 3)"OFF" Data, 4)"ON" Data
        temp_row_altimeter_data=cell_split_rtca_data{data_row_idx,6};
        
        %%%%%%Maybe find the number of frequencies (3) and split up the statstical processing based on each frequency.
        uni_freq=unique(cell2mat(temp_row_altimeter_data(:,1)));
        num_uni_freq=length(uni_freq);
        
        cell_freq_stats=cell(num_uni_freq,8);
        %%%1) Full Excel Name
        %%%2) Use Case
        %%%3) Altimeter
        %%%4) Altitude
        %%%5) Center Frequency
        %%%6) Criteria 1: Mean Height IntPwr
        %%%7) Criteria 2: Percentile Height IntPwr
        %%%8) Criteria 3: NCD IntPwr
        for freq_idx=1:1:num_uni_freq
            temp_freq_row_idx=find(cell2mat(temp_row_altimeter_data(:,1))==uni_freq(freq_idx));
            temp_freq_split_data=temp_row_altimeter_data(temp_freq_row_idx,:);
            [num_int_pwr,~]=size(temp_freq_split_data);
            
            array_mean_height=NaN(num_int_pwr,4); %%%%% 1) Frequency, 2) IntPwr, 3)Off, 4)On
            array_percentile=NaN(num_int_pwr,6); %%%%%% 1) Frequency, 2) IntPwr, 3)Off 1%, 4)Off 99%, 5)ON 1%, 6)On 99%
            array_tf_ncd=NaN(num_int_pwr,4); %%%%%%%%%% 1) Frequency, 2) IntPwr, 3)Off, 4)On
            for int_pwr_idx=1:1:num_int_pwr
                %%%%%%1)Excel time 2)height 3)CenterF 4)RFPwrDBM 5)RFState 6)NCD 7)Corrected Time in Seconds
                temp_off_data=temp_freq_split_data{int_pwr_idx,3};
                temp_on_data=temp_freq_split_data{int_pwr_idx,4};
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%1. Calculate the Mean Height
                array_mean_height(int_pwr_idx,1)=uni_freq(freq_idx);
                array_mean_height(int_pwr_idx,2)=temp_freq_split_data{int_pwr_idx,2};
                array_mean_height(int_pwr_idx,3)=mean(temp_off_data(:,2),'omitnan');
                array_mean_height(int_pwr_idx,4)=mean(temp_on_data(:,2),'omitnan');
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%2. Calculate the Percentile with an Empirical CDF
                %%%%%%%Interpolate the CDF because we don't have enough data
                %%%%%%%(which is something RTCA probably did not do)
                array_percentile(int_pwr_idx,1)=uni_freq(freq_idx);
                array_percentile(int_pwr_idx,2)=temp_freq_split_data{int_pwr_idx,2};
                
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
                array_tf_ncd(int_pwr_idx,2)=temp_freq_split_data{int_pwr_idx,2};
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
            temp_avg_height_off=array_mean_height(1,3);
            mean_height_error=(abs(array_mean_height(:,4)-temp_avg_height_off)/temp_avg_height_off)*100;  %%%Save this array
            mean_height_idx=find(mean_height_error>mean_height_error_percentage,1,'first');
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%2. Find the Percentile
            on_h1=array_percentile(:,5);
            on_h99=array_percentile(:,6);
            
            percentage_on_h1_idx=find(on_h1<(temp_avg_height_off-temp_avg_height_off*(avg_height_percentage/100)),1,'first');
            percentage_on_h99_idx=find(on_h99>(temp_avg_height_off+temp_avg_height_off*(avg_height_percentage/100)),1,'first');
            merge_h199_idx=min(horzcat(percentage_on_h1_idx,percentage_on_h99_idx));
            
            foot_off_h1_idx=find(on_h1<(temp_avg_height_off-percentile_foot_limit),1,'first');
            foot_off_h99_idx=find(on_h99>(temp_avg_height_off+percentile_foot_limit),1,'first');
            merge_foot_idx=min(horzcat(foot_off_h1_idx,foot_off_h99_idx));
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%3. Find if there is a NCD Flag
            ncd_idx=find(array_tf_ncd(:,4)==1,1,'first');
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Save the Threshold Interference Levels for Each Criteria
            %%%1) Full Excel Name
            %%%2) Use Case
            %%%3) Altimeter
            %%%4) Altitude
            %%%5) Center Frequency
            %%%6) Criteria 1: Mean Height IntPwr
            %%%7) Criteria 2: Percentile Height IntPwr
            %%%8) Criteria 3: NCD IntPwr
            % % % % % % % % % %         %%%9) Full Criteria 1 Data
            % % % % % % % % % %         %%%10) Full Criteria 2 Data
            % % % % % % % % % %         %%%11) Full Criteria 3 Data
            cell_freq_stats{freq_idx,1}=cell_split_rtca_data{data_row_idx,1};
            cell_freq_stats{freq_idx,2}=cell_split_rtca_data{data_row_idx,2};
            cell_freq_stats{freq_idx,3}=cell_split_rtca_data{data_row_idx,3};
            cell_freq_stats{freq_idx,4}=cell_split_rtca_data{data_row_idx,4};
            cell_freq_stats{freq_idx,5}=uni_freq(freq_idx);
            
            if ~isempty(mean_height_idx)==1
                cell_freq_stats{freq_idx,6}=array_mean_height(mean_height_idx,2);
            else
                cell_freq_stats{freq_idx,6}=NaN(1);
            end
            
            if ~isempty(merge_h199_idx)==1
                cell_freq_stats{freq_idx,7}=array_percentile(merge_h199_idx,2);
            else
                cell_freq_stats{freq_idx,7}=NaN(1);
            end
            
            if ~isempty(ncd_idx)==1
                cell_freq_stats{freq_idx,8}=array_tf_ncd(ncd_idx,2);
            else
                cell_freq_stats{freq_idx,8}=NaN(1);
            end
            % % % %         cell_freq_stats{freq_idx,9}=array_mean_height;
            % % % %         cell_freq_stats{freq_idx,10}=array_percentile;
            % % % %         cell_freq_stats{freq_idx,10}=array_tf_ncd;
            
            if tf_stats_plots==1
                close all;
                figure;
                hold on;
                yyaxis left
                %plot(array_mean_height(:,2),mean_height_error,':ob','LineWidth',1)
                plot(array_mean_height(:,2),mean_height_error,':o','Color',[62,105,225]/255,'LineWidth',1.5)
                if ~isempty(mean_height_idx)==1
                    plot([array_mean_height(mean_height_idx,2),array_mean_height(mean_height_idx,2)],[min(ylim),max(ylim)],'-b','LineWidth',4)
                    %plot([min(xlim),max(xlim)],[mean_height_error_percentage,mean_height_error_percentage],'--k','LineWidth',1)
                end
                
                if ~isempty(ncd_idx)==1
                    plot([array_tf_ncd(ncd_idx,2),array_tf_ncd(ncd_idx,2)],[min(ylim),max(ylim)],'-m','LineWidth',3)
                end
                %plot(array_mean_height(:,2),mean_height_error,':ob','LineWidth',1)
                plot(array_mean_height(:,2),mean_height_error,':o','Color',[62,105,225]/255,'LineWidth',1.5)
                ylabel('Mean Height Error (%)')
                %set(gca, 'YScale', 'log')
                
                yyaxis right
                %plot(array_mean_height(:,2),on_h1,':ob')
                plot(array_mean_height(:,2),on_h1,':o','Color',[255,128,0]/255,'LineWidth',1.5)
                if ~isempty(merge_h199_idx)==1
                    %plot([array_percentile(merge_h199_idx,2),array_percentile(merge_h199_idx,2)],[min(ylim),max(ylim)],'-b','LineWidth',2)
                     plot([array_percentile(merge_h199_idx,2),array_percentile(merge_h199_idx,2)],[min(ylim),max(ylim)],'-','Color',[255,128,0]/255,'LineWidth',2)
                end
                ylabel(strcat('Average Height Percentile'))
                grid on;
                xlabel('Interference Power (dBm)')
                title(strcat(cell_split_rtca_data{data_row_idx,1},'---Center Frequency:',num2str(uni_freq(freq_idx)),'MHz'))
                filename1=strcat('Int_',cell_split_rtca_data{data_row_idx,1},'_',num2str(uni_freq(freq_idx)),'MHz.png');
                saveas(gcf,char(filename1))
                pause(0.1);
            end
            
            
        end
        cell_stats_rtca_data{data_row_idx}=cell_freq_stats;
    end
    toc;
    
    %%%%%Save
    tic;
    retry_save=1;
    while(retry_save==1)
        try
            save(cell_stats_rtca_data_filename,'cell_stats_rtca_data')  
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
            load(cell_stats_rtca_data_filename,'cell_stats_rtca_data') 
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