function gitar_sentez_uygulamasi()
    fig = figure('Name', 'Gitar Sentez Uygulaması', 'Position', [300, 300, 600, 350]);

    % --- Sentez tipi menüsü ---
    uicontrol('Style', 'text', 'Position', [50, 300, 100, 20], 'String', 'Sentez Tipi:');
    sentezMenu = uicontrol('Style', 'popupmenu', 'Position', [50, 280, 100, 20], ...
        'String', {'Wavetable', 'Additive'}, ...
        'Callback', @(src, event) toggleWaveformMenu());

    % --- Nota menüsü ---
    uicontrol('Style', 'text', 'Position', [200, 300, 100, 20], 'String', 'Nota:');
    notaMenu = uicontrol('Style', 'popupmenu', 'Position', [200, 280, 100, 20], ...
        'String', {'Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Si'});

    % --- Dalga formu menüsü ---
    waveformLabel = uicontrol('Style', 'text', 'Position', [350, 300, 100, 20], ...
        'String', 'Dalga Formu:');
    waveformMenu = uicontrol('Style', 'popupmenu', 'Position', [350, 280, 100, 20], ...
        'String', {'Sinüs', 'Üçgen', 'Testere', 'Kare'});

    % --- Grafik alanı ---
    ax = axes('Parent', fig, 'Position', [0.1 0.1 0.8 0.5]);

    % --- Çal butonu ---
    uicontrol('Style', 'pushbutton', 'Position', [200, 230, 100, 30], ...
        'String', 'Nota Çal', ...
        'Callback', @(src, event) ses_uret(sentezMenu, notaMenu, waveformMenu, ax));

    % İlk durumda dalga formu menüsü açık/kapatılır
    toggleWaveformMenu();

    function toggleWaveformMenu()
        tip = get(sentezMenu, 'Value');
        if tip == 1  % Wavetable seçili ise göster
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

    if sentezTipi == 1  % Wavetable
        waveformIdx = get(waveformMenu, 'Value');
        waveformAdi = waveformNames{waveformIdx};
        y = wavetable_sentez(f0, t, Fs, waveformIdx);
        dosyaAdi = sprintf('%s_%s_%s.wav', notaAdi, sentezAdi, waveformAdi);
    else  % Additive
        y = additive_sentez(f0, t);
        dosyaAdi = sprintf('%s_%s.wav', notaAdi, sentezAdi);
    end

    % Normalize et (taşmayı önlemek için)
    y = y / max(abs(y));

    % Ses çal ve kaydet
    sound(y, Fs);
    audiowrite(dosyaAdi, y, Fs);

    % Dalga formunu çiz
    plot(ax, t(1:1000), y(1:1000));
    title(ax, 'Oluşturulan Dalga');
    xlabel(ax, 'Zaman (s)');
    ylabel(ax, 'Genlik');
end

function y = wavetable_sentez(f0, t, Fs, waveformIdx)
    wavetableSize = 1024;

    % Dalga tabloları oluşturuluyor
    switch waveformIdx
        case 1  % Sinüs
            wavetable = sin(2 * pi * (0:wavetableSize-1) / wavetableSize);
        case 2  % Üçgen
            wavetable = 2 * abs(2 * ((0:wavetableSize-1)/wavetableSize - ...
                        floor((0:wavetableSize-1)/wavetableSize + 0.5))) - 1;
        case 3  % Testere
            wavetable = 2 * ((0:wavetableSize-1) / wavetableSize) - 1;
        case 4  % Kare
            wavetable = ones(1, wavetableSize);
            wavetable(1:round(wavetableSize/2)) = -1;
        otherwise
            wavetable = zeros(1, wavetableSize);
    end

    % Faz dizisi (0..1 aralığında)
    phase = mod(f0 * t, 1);

    % İndeksler (1 tabanlı)
    index_float = phase * wavetableSize + 1;

    % İndekslerin alt ve üst tam kısmı
    index_low = floor(index_float);
    index_high = index_low + 1;

    % Döngü için sınır kontrolü
    index_high(index_high > wavetableSize) = 1;

    % Lineer interpolasyon ağırlıkları
    alpha = index_float - index_low;

    % Lineer interpolasyonla dalga tablosundan örnekler
    y = (1 - alpha) .* wavetable(index_low) + alpha .* wavetable(index_high);
end

function y = additive_sentez(f0, t)
    y = zeros(size(t));
    N = 10; % Harmonik sayısı
    for n = 1:N
        y = y + (1/n) * sin(2 * pi * n * f0 * t);
    end
    y = y * (2 / pi); % normalize
end
