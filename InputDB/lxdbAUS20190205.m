%clearall

global nofluctM nofluctF
% adjust these according to diagnostics
% likely we ignore fluctuations in the earlier version because the
% open age group was so low, and it was year of registration data anyway
% nofluctM=1921:1963;
% nofluctF=1921:1963;

dbstop if error
Name = 'AUS';

% code for user =  Kirill only
%if ~isempty(regexpi(getenv('username'), 'Kirill'))
%    workfolder = ['E:\!Home\HMD\HMDWork\' Name '\'];
%    % code for user =  Kirill only
%    addpath E:\!Home\HMD\MPIMirror\Soft\Lexis
%    addpath(['E:\!Home\HMD\HMDWork\' Name '\Matlab']);
%    cd([workfolder 'Matlab']);
%    cd('..\indb');
%end

indb_input('AUS');
load AUS;

disp('select data using LDB column')
d      = selif(deaths, deaths(:, end) == 1);
d      = d(:,1:end-1);
p      = selif(population, population(:, end) == 1);
p      = p(:,1:end-1);
births = selif(births, births(:, end) == 1);
births = births(:,1:end-1);

clear deaths;
clear population;   

disp('process deaths')
disp('impute 0s as needed')
d      = d_ma0(d);

disp('split 5x1 to 1x1 rectangles');
d      = d_s5x1(d);

disp('split 1x1 squares to triangles based on recorded triangles');
d      = d_rr2tltu(d); 

disp('split 1x1 squares based on MP appendix');
d      = d_s1x1(d, births);

disp('split VV parallelograms into triangles');
d      = d_svv(d);

disp('redistribute deaths open age interval');
d      = d_soainew(d,1964);

disp('long');
d      = d_long(d);

disp('distribution of unknown');
d      = d_unk(d);

disp('process population counts')
%p=p_postcensal(p, d, births, [2005, 2005]);
disp('calculate recent population counts as weighted average of midyear counts')
p      = p_movedata(p);

disp('Distribute population unknowns.')
p      = p_unk(p);

%disp('survivor ratio and extinct cohort methods on post 1921 data')
% this is necessary in order to extend the jan 1 1922 population estimates to high ages
% prior to running the intercensals. Otherwise 1911 tries to connect with 85+, followed
% by zeros in higher ages and produces some NA estimates. Similar hack found elsewhere in 
% cocktail scripts
%p1922 = selif(p,p(:,5) >= 1922);
%d1922 = selif(d,d(:,3) >= 1922);
%pEarly = selif(p,p(:,5) < 1922);
%p1922 = p_srecm(p1922, d1922);
% now stick back together
%p = [pEarly;p1922];
%clear p1922;
%clear pEarly;
%clear d1922;
%disp('do intercensal estimates for Jan1, 1912 to Jan 1, 1921')
% the interesting difference here is that 1922 goes to a higher age now
%p      = p_ic(p, d, births);

%disp('stimate Jan 1 1911 population counts (census from April 3, 1911)')
%p      = p_precensal(p, d, [1911, 1911]);
disp('Get Jan 1 1921 population counts ')
p=p_precensal(p, d, [1921, 1921]);

disp('survivor ratio and extinct cohort methods')
% rerun in order to reestimate old ages pre 1922
%p      = [selif(p, p(:,5) < 2017)];
p      = p_srecm(p, d);

% no terr adj
disp('write LexisDB files')
ldb_output(d, p, 'mAUS.txt', 'fAUS.txt', births);
d_printRA('AUS','Australia');

