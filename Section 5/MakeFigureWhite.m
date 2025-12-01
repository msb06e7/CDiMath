function MakeFigureWhite(fh)
% MakeFigureWhite(fh)
%   fh: figure handle (예: gcf)
%   - Figure 배경: 흰색
%   - Axes 배경: 흰색
%   - 축, title, label, colorbar, text: 검정색

    if nargin < 1
        fh = gcf;
    end

    % Figure 배경
    set(fh, 'Color', 'w');

    % 모든 axes에 대해서
    axList = findall(fh, 'Type', 'axes');
    for k = 1:numel(axList)
        ax = axList(k);
        set(ax, 'Color', 'w', ...
                'XColor', 'k', ...
                'YColor', 'k', ...
                'ZColor', 'k');

        % 축 제목, 라벨들 (혹시 이미 설정돼 있으면 색만 바꿈)
        t = get(ax, 'Title');
        set(t, 'Color', 'k');
        xl = get(ax, 'XLabel');
        set(xl, 'Color', 'k');
        yl = get(ax, 'YLabel');
        set(yl, 'Color', 'k');
        zl = get(ax, 'ZLabel');
        set(zl, 'Color', 'k');
    end

    % 컬러바 (있으면)
    cbList = findall(fh, 'Type', 'ColorBar');
    for k = 1:numel(cbList)
        cb = cbList(k);
        set(cb, 'Color', 'k');   % 눈금/레이블 색
    end

    % 기타 text object 들도 전부 검정색으로
    txtList = findall(fh, 'Type', 'text');
    set(txtList, 'Color', 'k');
end