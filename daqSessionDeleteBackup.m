% daqSessionDeleteBackup.m deletes the backup file that was logging the
% data

global session % our global variable to store everything

if exist([session.dataFilename '_backup.txt'],'file')
   delete([session.dataFilename '_backup.txt'])
end    
