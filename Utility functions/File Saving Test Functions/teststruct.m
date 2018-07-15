clear
Metadata.Name1.value='x';
Metadata.Name2.value='y';
names=fieldnames(Metadata)
% Metadata=setfield(Metadata,names{:},'str_spec','%s');
Metadata.(names{1}).str_spec='%s';

Metadata.Name1