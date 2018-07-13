clear
this=struct();
file_path='M:\Measurement Campaigns\2018-02-12 placeholder\placeholder.txt';

fileid=fopen(file_path);
line_no=0;
if strcmpi(fgetl(fileid),'%BEGIN HEADER')
    line_no=1;
    in_header=true;
    while in_header
        curr_line=fgetl(fileid);
        in_header=~strcmpi(curr_line,'%END HEADER');
        line_no=line_no+1;
    end
end

read_opts=detectImportOptions(file_path);
DataTable=readtable(file_path,...
    'HeaderLines',line_no,...
    'ReadVariableNames',true);
data_labels=DataTable.Properties.VariableNames;

%Finds where the unit is specified, within parantheses.
%Forces indices to be in cells for later.
ind_start=strfind(data_labels, '(','ForceCellOutput',true);
ind_stop=strfind(data_labels, ')','ForceCellOutput',true);

col_name={'x','y'};
for i=1:length(ind_start)
    if ~isempty(ind_start{i}) && ~isempty(ind_stop{i})
        %Extracts the data labels from the file
        this.(sprintf('unit_%s',col_name{i}))=...
            data_labels{i}((ind_start{i}+4):(ind_stop{i}-1));
        this.(sprintf('name_%s',col_name{i}))=...
            data_labels{i}(1:(ind_start{i}-2));
    end
    %Loads the data into the trace
    this.(col_name{i})=DataTable.(data_labels{i});
end
this.load_path=file_path;

testimport=importdata(file_path);