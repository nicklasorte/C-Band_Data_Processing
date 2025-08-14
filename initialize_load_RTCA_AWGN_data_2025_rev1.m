clear;
clc;
close all;
close all force;
top_start_clock=clock;
app=NaN(1);  %%%%%%%%%%%%This is a placeholder for Matlab APPs
format shortG;%format longG;
folder1='C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\CBand'
cd(folder1)
addpath(folder1)
addpath('C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\Basic_Functions')
pause(0.1); %%%Matlab needs this momentary pause for some reason when changing folders




% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % Consider Looking at the Response Time after the interference is off
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % to see how long it takes the alimeter to get back within an
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % acceptable level performance.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Inputs
tf_reimport_spur_data=0;%1%0%1%0;%%%%1;           %%%%%%Reimport the RTCA data (if we changed some values)
tf_resplit_data=0;%%0%1%0;%%%%%1;
tf_recreate_excel_plots=0;%1%0%1;  %%%%%%Plots and Save "Recreated" Excel Plots
tf_stats_data_spur=0;%1%0%1%0%1%0%1%0; %%%%%%%This determines the 3 interference criteria for the data
tf_stats_plots_spur=0;%1%0%1%0%1;                 %%%%This is where we plot the processed data
data_folder='C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\CBand\AWGN';
avsi_spurrious_data='Spurious Data Summary.xlsx'
tf_import_spurious=0;%1%0
band_stop_filter_correction=horzcat(vertcat(3750,3850,3930),vertcat(0,0,0)); %%%%%They apply the correction after.
filter_corr_post_scrap=horzcat(vertcat(3750,3850,3930),vertcat(1,2,5))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%3 Altimater Interference Tolerance Threshold Criteria
%%%%%%Criteria 1. Mean Height Error Greater than 0.5%
mean_height_error_percentage=0.5; %%%%%% 0.5 Percent

%%%%%%Criteria 2. Fewer than 98% of all data points fall with 2% (of the Average height) or 1.5 foot limits
percentile_threshold=98; %%%%% or 1% and 99%
avg_height_percentage=2; %%%%% 1% and 99% data points fall within 2% of the average height or
percentile_foot_limit=1.5; %%%%%1.5 foot limit (not being used at this point)

%%%%%%Criteria 3. NCD Flags (No Variables)

time_window_cut=1.75; %%%%%%Seconds. The time constant used was 1.75 seconds from the beginning and end of the interference power OFF subinterval.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Step 0: Load the AVSI Excel data
%%%%%%%[cell_fundamental_avsi_data]=load_fund_avsi_data_rev1(app,avsi_fundamental_data,tf_import_fundatmental)
[cell_spurrious_avsi_data]=load_spurious_avsi_data_rev1(app,avsi_spurrious_data,tf_import_spurious);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Step 1: Load the Excel data
%%%%%%%%%%%%%%%%[cell_all_rtca_data]=load_rtca_data_rev1(app,data_folder,folder1,tf_reimport_data);
%[cell_all_rtca_data]=load_rtca_data_dual_rev2(app,data_folder,folder1,tf_reimport_data);
[cell_all_rtca_data_spur]=load_rtca_spur_data_rev1(app,data_folder,folder1,tf_reimport_spur_data);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 %%%%%%cell_all_rtca_data%%%%%% 1) Full Name, 2) Use Case, 3) Altimeter, 4) Altitude 5)Data (Full Raw: Just 4300MHz)
 
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Step 2: Split Data (Break into Frequency and Interference Power)
%%%%%%%%[cell_split_rtca_data]=split_rtca_data_rev1(app,cell_all_rtca_data,data_folder,folder1,tf_resplit_data,tf_recreate_excel_plots);
%[cell_split_rtca_data]=split_rtca_data_rev2(app,cell_all_rtca_data,data_folder,folder1,tf_resplit_data,tf_recreate_excel_plots); %%%%%%%The Time data was very close.
 [cell_split_rtca_data_spur]=split_spur_rtca_data_rev1(app,cell_all_rtca_data_spur,data_folder,folder1,tf_resplit_data,tf_recreate_excel_plots);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Step 3: Statstical Analysis of Data to determine the interference criteria
%[cell_stats_rtca_data]=interference_criteria_rtca_data_rev1(app,cell_split_rtca_data,data_folder,folder1,tf_stats_data,tf_stats_plots,mean_height_error_percentage,percentile_threshold,avg_height_percentage,percentile_foot_limit);
[cell_stats_rtca_data_spur]=interference_criteria_rtca_data_spur_rev1(app,cell_split_rtca_data_spur,data_folder,folder1,tf_stats_data_spur,tf_stats_plots_spur,mean_height_error_percentage,percentile_threshold,avg_height_percentage,percentile_foot_limit,time_window_cut);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Save to excel files
num_rows=length(cell_stats_rtca_data_spur);
cut_cell_stats_rtca_data_spur=cell(num_rows,1);  %%%%%All three criteria, and then the minimum
for row_idx=1:1:num_rows
    temp_cell_data=cell_stats_rtca_data_spur{row_idx};
    cut_cell_stats_rtca_data_spur{row_idx,1}=horzcat(temp_cell_data(:,[1:9]),mat2cell(min(cell2mat(temp_cell_data(:,[6:9])),[],2),[1],[1]));
end
cell_array_stats_rtca_data_spur=vertcat(cut_cell_stats_rtca_data_spur{:});

%%%%%%%%%%%%%%%%%%%%%%Full Table
full_stats_table=cell2table(cell_array_stats_rtca_data_spur);
full_stats_table.Properties.VariableNames={'Excel_Name' 'Use_Case' 'Altimeter' 'Altitude' 'Frequency' 'Criteria_1_Mean' 'Criteria_2_1%' 'Criteria_2_99%' 'Criteria_3_NCD' 'Breakpoint'};
tic;
writetable(full_stats_table,strcat('Spurious_Full_Int_',num2str(mean_height_error_percentage),'_',num2str(percentile_threshold),'_',num2str(avg_height_percentage),'.xlsx'));
toc;


%%%%%%%%%%%%%%%%%%%%%%cell_stats_rtca_data_spur
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

%%%%%%%%%%Make a graph, normalizing the interference point
num_rows=length(cell_stats_rtca_data_spur)
cell_norm_data=cell(num_rows,1);
for i=1:1:num_rows
    temp_row_data=cell_stats_rtca_data_spur{i};
    array_int_point=cell2mat(temp_row_data(6:9));

    [min_pwr,min_idx]=min(array_int_point);

    if min_idx==1
        data_idx=10;
        temp_exp_data=temp_row_data{data_idx};
        norm_data=temp_exp_data(:,[2,5]);  %%%%%Only keep row 2 and row 5, normalize row 2: 1) Norm dB and 2)Percentile Error
        norm_data(:,2)=abs(norm_data(:,2));
        norm_data(:,1)=norm_data(:,1)-min_pwr;
        cell_norm_data{i}=norm_data;
    elseif min_idx==2 || min_idx==3
        data_idx=11;
        temp_exp_data=temp_row_data{data_idx};

        %%%%%%Pull row 8/10 to find where the interference was
        tf_int=temp_exp_data(:,[8,10]);
        %%%%%%Find the column with the first 1.
        col1_tf_idx=find(tf_int(:,1)==1);
        col2_tf_idx=find(tf_int(:,2)==1);

        min_col1_idx=min(col1_tf_idx);
        min_col2_idx=min(col2_tf_idx);

        %%%%%Calculate Error for both rows, take the worst error
        %%%' col1'
        on_h1=temp_exp_data(:,5);
        array_1p=(temp_exp_data(:,3)-(temp_exp_data(:,3).*(avg_height_percentage/100)));
        on_h1_percentage=abs((on_h1-temp_exp_data(:,3))./temp_exp_data(:,3)*100);
        norm_data1=horzcat(temp_exp_data(:,[2]),on_h1_percentage);
        norm_data1(:,1)=norm_data1(:,1)-min_pwr;

        %%%'col2'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%2. Find the Percentile
        on_h99=temp_exp_data(:,6);
        array_99p=(temp_exp_data(:,3)+(temp_exp_data(:,3).*(avg_height_percentage/100)));
        on_h99_percentage=abs((on_h99-temp_exp_data(:,3))./temp_exp_data(:,3)*100);
        norm_data2=horzcat(temp_exp_data(:,[2]),on_h99_percentage);
        norm_data2(:,1)=norm_data2(:,1)-min_pwr;

        if isempty(min_col1_idx)
            %%'Use col2'
            cell_norm_data{i}=norm_data2;
        elseif isempty(min_col2_idx)
            %%%'use col1'
            cell_norm_data{i}=norm_data1;
        else
            if min_col1_idx==min_col2_idx
                %%%'Take largest error'
                norm_data3=norm_data1;
                norm_data3(:,2)=max(horzcat(norm_data2(:,2),norm_data1(:,2)),[],2);
                cell_norm_data{i}=norm_data3;
            elseif min_col1_idx<min_col2_idx
                %%%'use col1'
                cell_norm_data{i}=norm_data1;
            elseif min_col1_idx>min_col2_idx
                %%'Use col2'
                cell_norm_data{i}=norm_data2;
            else
                'Figure which one to use'
                pause;
            end
        end
    elseif min_idx==4
        data_idx=12;
        temp_exp_data=temp_row_data{data_idx};
        %'see if it holds here, nope, just a flag'
        %pause;
    else
        'min_idx error'
        pause;
    end

end

cell_norm_data=cell_norm_data(~cellfun('isempty',cell_norm_data)) ;
num_norm_rows=length(cell_norm_data);

% % 
% % 
% % cell_cut_data=cell(num_norm_rows,1);
% % for i=1:1:num_norm_rows
% %     temp_data=cell_norm_data{i};
% %     above_100_idx=find(temp_data(:,2)>100);
% %     temp_data(above_100_idx,2)=100;
% %     before0_idx=find(temp_data(:,1)<=0);
% %     temp_data(before0_idx,1)=0;
% % 
% % 
% %     %%%%%%%Only keep the first 0
% %     start_idx=find(temp_data(:,1)==0,1,'last');
% %     cut_temp_data=temp_data([start_idx:end],:);
% %     cut_temp_data(:,2)=rescale(cut_temp_data(:,2),0,1)
% %     cell_cut_data{i}=cut_temp_data;
% % 
% %     close all;
% %     figure;
% %     hold on;
% %     plot(cut_temp_data(:,1),cut_temp_data(:,2),'-')
% %     grid on;
% %     ylabel('Normalized Height Error')
% %     grid on;
% %     xlabel('Normalized Interference Power (dBm)')
% %     title(strcat('4200-4400MHz Int:',num2str(i)))
% %     filename1=strcat('AWGN_Normalized_Error_',num2str(i),'.png');
% %     saveas(gcf,char(filename1))
% %     pause(0.1);
% % 
% % 
% % end
% % 
% % cellsz=cell2mat(cellfun(@size,cell_cut_data,'uni',false));
% % min_size=min(cellsz,[],1)
% % min_size_len=min_size(1)
% % 
% % 
% % %%plot(temp_data(1:min_size_len,1),mean_data,'-r','LineWidth',2)  %%This is wrong, need to pull data from last 0 and then the rest.
% % 









%%%%%%%%%%%%%%%%%%%'Compare to the AVSI Data
spur_avsi_ext=cell_spurrious_avsi_data{2};
[num_rows,~]=size(spur_avsi_ext);
cell_compare_data=cell(num_rows,1); %%%%Keep the same order as the AVSI data
tic;
for row_idx=1:1:num_rows
    single_avsi_row=spur_avsi_ext(row_idx,:);

    %%%%%Find the Corresponding computed data
    eut_row_idx=find(contains(cell_array_stats_rtca_data_spur(:,3),single_avsi_row{3})==1);
    temp_text_freq=single_avsi_row{5};
    temp_cell_split=strsplit(temp_text_freq,' ');
    freq_row_idx=find(cell2mat(cell_array_stats_rtca_data_spur(:,5))==str2num(temp_cell_split{1})==1);
    alt_row_idx=find(cell2mat(cell_array_stats_rtca_data_spur(:,4))==single_avsi_row{4}==1);
    temp_text_uc=single_avsi_row{2};
    temp_cell_split2=strsplit(temp_text_uc,'UC');
    uc_row_idx=find(cell2mat(cell_array_stats_rtca_data_spur(:,2))==str2num(temp_cell_split2{2})==1);
    inter_row_idx=intersect(intersect(eut_row_idx,freq_row_idx),intersect(alt_row_idx,uc_row_idx));
    if isempty(inter_row_idx)==1 || length(inter_row_idx)>1
        'Intersection Error'
        pause;
    end
    %%%%%cell_array_stats_rtca_data(inter_row_idx,:)

    %%%%%%%%%%%%%%Compare the I:M columns of all the criteria. In terms of
    %%%%%%%%%%%%%%difference and mark if there was "engineering judgment"
    
    three_crit_avsi=single_avsi_row(7:10);
    three_crit_ntia=cell2mat(cell_array_stats_rtca_data_spur(inter_row_idx,[6:9]));
    for j=1:1:length(three_crit_avsi)  %%%%%%%Need to Replace 'X' with 'NaN'
        if ischar(three_crit_avsi{j})==1
            if contains(three_crit_avsi{j},'X')==1
                three_crit_avsi{j}=NaN(1);
            end
        end
    end
    three_crit_avsi=cell2mat(three_crit_avsi);
    diff_crit=num2cell(three_crit_avsi-(three_crit_ntia+1));  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%We need to add a +1 because they calculated the break point and we calculated the last good point
    cell_compare_data{row_idx}=horzcat(single_avsi_row(2:5),diff_crit,single_avsi_row(11));
end
toc;

%%%%%%%%%%%%%%%%%%%%%%Compare Table
compare_stats_table=cell2table(vertcat(cell_compare_data{:}));
compare_stats_table.Properties.VariableNames={'Use_Case' 'Altimeter' 'Altitude' 'Frequency' 'Criteria_1_Mean' 'Criteria_2_1%' 'Criteria_2_99%' 'Criteria_3_NCD' 'Engineering_Judgment'};
tic;
writetable(compare_stats_table,strcat('Spurious_Compare_Int_',num2str(mean_height_error_percentage),'_',num2str(percentile_threshold),'_',num2str(avg_height_percentage),'.xlsx'));
toc;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Next Step: Create the Section 9.2 Plots/Tables in the RC-239 report.

%%%%%%%Now build the Section 9 Tables from both sets of data.

%%%%Might need to add the filter correction, plus the 6dB.


%%%%%For Each Class/Altimeter/Frequecny, find the highest interference power threshold.




























end_clock=clock;
total_clock=end_clock-top_start_clock;
total_seconds=total_clock(6)+total_clock(5)*60+total_clock(4)*3600+total_clock(3)*86400;
total_mins=total_seconds/60;
total_hours=total_mins/60;
if total_hours>1
    strcat('Total Hours:',num2str(total_hours))
elseif total_mins>1
    strcat('Total Minutes:',num2str(total_mins))
else
    strcat('Total Seconds:',num2str(total_seconds))
end




'Done'