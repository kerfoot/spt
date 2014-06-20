function title_string = toptitle(string)
%
% Places a title over a set of subplots.  The string is assigned the tag
% 'topTitle'.  Best results are obtained when all subplots are created and 
% then toptitle is executed.
%
% Usage: h = toptitle('title string')
%          
%
% Patrick Marchand (prmarchand@nvidia.com)
% Thomas Holland (tholland@infinityassociates.com)
% John Kerfoot (kerfoot@marine.rutgers.edu)
%

titlepos = [.5 1]; % normalized units.

ax = gca;
set(ax,...
    'units','normalized');
axpos = get(ax, 'position');

offset = (titlepos - axpos(1:2))./axpos(3:4);

title_string = text(offset(1),offset(2),string,...
    'units', 'normalized',...
    'horizontalalignment', 'center',...
    'verticalalignment', 'middle',...
    'Tag', 'topTitle');

% Make the figure big enough so that when printed the
% toptitle is not cut off nor overlaps a subplot title.
h = findobj(gcf,...
    'type', 'axes');
set(h,...
    'units', 'points');
set(gcf,...
    'units', 'points');

figpos = get(gcf, 'position');
set(gcf, 'position', figpos + [0 0 0 5])
set(gcf,...
    'units', 'pixels');
set(h,...
    'units', 'normalized');
