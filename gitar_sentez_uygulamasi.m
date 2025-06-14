function gitar_sentez_uygulamasi()
    fig = figure('Name', 'Gitar Sentez Uygulaması', 'Position', [300, 300, 620, 360]);

    uicontrol('Style', 'text', 'Position', [50, 300, 100, 20], 'String', 'Sentez Tipi:');
    sentezMenu = uicontrol('Style', 'popupmenu', 'Position', [50, 280, 100, 20], ...
        'String', {'Wavetable', 'Additive'}, ...
        'Callback', @(src, event) toggleWaveformMenu());

    uicontrol('Style', 'text', 'Position', [200, 300, 100, 20], 'String', 'Nota:');
    notaMenu = uicontrol('Style', 'popupmenu', 'Position', [200, 280, 100, 20], ...
        'String', {'Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Si'});

    waveformLabel = uicontrol('Style', 'text', 'Position', [350, 300, 100, 20], ...
        'String', 'Dalga Formu:');
    waveformMenu = uicontrol('Style', 'popupmenu', 'Position', [350, 280, 100, 20], ...
        'String', {'Sinüs', 'Üçgen', 'Testere', 'Kare'});

    ax = axes('Parent', fig, 'Position', [0.1 0.1 0.55 0.4]);

    uicontrol('Style', 'pushbutton', 'Position', [200, 230, 100, 30], ...
        'String', 'Nota Çal', ...
        'Callback', @(src, event) ses_uret(sentezMenu, notaMenu, waveformMenu, ax));

    uicontrol('Style', 'text', 'Position', [480, 300, 100, 20], 'String', 'Melodi Notaları:');
    melodiList = uicontrol('Style', 'listbox', 'Position', [480, 180, 100, 120], ...
        'String', {}, 'Max', 2, 'Min', 0);

    uicontrol('Style', 'pushbutton', 'Position', [480, 150, 100, 25], ...
        'String', 'Nota Ekle', ...
        'Callback', @(src, event) nota_ekle(notaMenu, melodiList));

    uicontrol('Style', 'pushbutton', 'Position', [480, 120, 100, 25], ...
        'String', 'Melodi Çal', ...
        'Callback', @(src, event) melodi_uret(sentezMenu, melodiList, waveformMenu, ax));

    uicontrol('Style', 'pushbutton', 'Position', [480, 90, 100, 25], ...
        'String', 'Temizle', ...
        'Callback', @(src, event) set(melodiList, 'String', {}));

    toggleWaveformMenu();

    function toggleWaveformMenu()
        tip = get(sentezMenu, 'Value');
        if tip == 1  % Wavetable
            set(waveformMenu, 'Visible', 'on');
            set(waveformLabel, 'Visible', 'on');
        else
            set(waveformMenu, 'Visible', 'off');
            set(waveformLabel, 'Visible', 'off');
        end
    end
end

function ses_uret(sentezMenu, notaMenu, waveformMenu, ax)
    Fs = 44100;
    duration = 2;
    t = 0:1/Fs:duration;

    frekanslar = [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88];
    notalar = {'Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Si'};
    waveformNames = {'Sinüs', 'Üçgen', 'Testere', 'Kare'};
    sentezTipiAdlari = {'Wavetable', 'Additive'};

    notaIdx = get(notaMenu, 'Value');
    f0 = frekanslar(notaIdx);
    notaAdi = notalar{notaIdx};
    sentezTipi = get(sentezMenu, 'Value');
    sentezAdi = sentezTipiAdlari{sentezTipi};

    if sentezTipi == 1
        waveformIdx = get(waveformMenu, 'Value');
        waveformAdi = waveformNames{waveformIdx};
        y = wavetable_sentez(f0, t, Fs, waveformIdx);
        dosyaAdi = sprintf('%s_%s_%s.wav', notaAdi, sentezAdi, waveformAdi);
    else
        y = additive_sentez(f0, t);
        dosyaAdi = sprintf('%s_%s.wav', notaAdi, sentezAdi);
    end

    y = y / max(abs(y));
    sound(y, Fs);
    audiowrite(dosyaAdi, y, Fs);

    plot(ax, t(1:1000), y(1:1000));
    title(ax, 'Oluşturulan Dalga');
    xlabel(ax, 'Zaman (s)');
    ylabel(ax, 'Genlik');
end

function y = wavetable_sentez(f0, t, Fs, waveformIdx)
    wavetableSize = 1024;

    switch waveformIdx
        case 1
            wavetable = sin(2 * pi * (0:wavetableSize-1) / wavetableSize);
        case 2
            wavetable = 2 * abs(2 * ((0:wavetableSize-1)/wavetableSize - ...
                        floor((0:wavetableSize-1)/wavetableSize + 0.5))) - 1;
        case 3
            wavetable = 2 * ((0:wavetableSize-1) / wavetableSize) - 1;
        case 4
            wavetable = ones(1, wavetableSize);
            wavetable(1:round(wavetableSize/2)) = -1;
        otherwise
            wavetable = zeros(1, wavetableSize);
    end

    phase = mod(f0 * t, 1);
    index_float = phase * wavetableSize + 1;
    index_low = floor(index_float);
    index_high = index_low + 1;
    index_high(index_high > wavetableSize) = 1;
    alpha = index_float - index_low;
    y = (1 - alpha) .* wavetable(index_low) + alpha .* wavetable(index_high);
end

function y = additive_sentez(f0, t)
    y = zeros(size(t));
    N = 10;
    for n = 1:N
        y = y + (1/n) * sin(2 * pi * n * f0 * t);
    end
    y = y * (2 / pi);
end

function nota_ekle(notaMenu, melodiList)
    notalar = {'Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Si'};
    mevcut = get(melodiList, 'String');
    yeniNota = notalar{get(notaMenu, 'Value')};
    set(melodiList, 'String', [mevcut; {yeniNota}]);
end

function melodi_uret(sentezMenu, melodiList, waveformMenu, ax)
    Fs = 44100;
    t_nota = 0:1/Fs:0.5;
    frekanslar = [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88];
    notalar = {'Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Si'};
    sentezTipi = get(sentezMenu, 'Value');

    secilenNotalar = get(melodiList, 'String');
    if isempty(secilenNotalar)
        return;
    end

    melodi = [];
    for i = 1:length(secilenNotalar)
        idx = find(strcmp(notalar, secilenNotalar{i}));
        f0 = frekanslar(idx);

        if sentezTipi == 1
            waveformIdx = get(waveformMenu, 'Value');
            nota = wavetable_sentez(f0, t_nota, Fs, waveformIdx);
        else
            nota = additive_sentez(f0, t_nota);
        end

        nota = nota / max(abs(nota));
        melodi = [melodi, nota];
    end

    sound(melodi, Fs);
    audiowrite('melodi.wav', melodi, Fs);

    t_melodi = (0:length(melodi)-1)/Fs;
    plot(ax, t_melodi(1:min(1000,end)), melodi(1:min(1000,end)));
    title(ax, 'Melodi Dalga Formu');
    xlabel(ax, 'Zaman (s)');
    ylabel(ax, 'Genlik');
end
