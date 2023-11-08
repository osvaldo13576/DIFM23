classdef Prueba_PF < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        PruebaPicketFenceUIFigure  matlab.ui.Figure
        VerimagenoriginalCheckBox  matlab.ui.control.CheckBox
        ResultadosListBox          matlab.ui.control.ListBox
        ResultadosListBoxLabel     matlab.ui.control.Label
        GuardarImgButton           matlab.ui.control.Button
        CerrarButton               matlab.ui.control.Button
        outputTextArea             matlab.ui.control.TextArea
        Image2                     matlab.ui.control.Image
        Image1                     matlab.ui.control.Image
        CrearreportepdfButton      matlab.ui.control.Button
        DirectorioEditField        matlab.ui.control.EditField
        IniciaranlisisButton       matlab.ui.control.Button
        DirectorioEditFieldLabel   matlab.ui.control.Label
        CargarimagenButton         matlab.ui.control.Button
        AbrirButton                matlab.ui.control.Button
        UIAxes4                    matlab.ui.control.UIAxes
        UIAxes3                    matlab.ui.control.UIAxes
        UIAxes                     matlab.ui.control.UIAxes
        UIAxes2                    matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        img % imagen DICOM
        img_8bit % imagen con rango dinamico de 8bits
        img_info % informacion del archivo DICOM
        directorio
        salida % ver salidas y otra informacion
        archivo
        elekta_true 
        varian_true
        img_fig % variable grafica de la imagen
        px % posicion de perfil x
        py % posicion de perfil y
        linea_px
        linea_py
        linea_px_perfil
        linea_py_perfil
        perfil_h_fig %elemento grafico
        perfil_v_fig
        error_grafica % grafico de error
        clic_on = false;
        desviacion_es % 
        desv_sort
        desv_loc
    end
    
    methods (Access = private)
        
        function [] = perfiles(app,x,y)
            x = round(x);
            y = round(y);
            ancho = app.img_info.Width;
            altura = app.img_info.Height;
             if x > ancho
                x = ancho;
            elseif x<1
                x = 1;
            end
            if y > altura
                y = altura;
            elseif y<1
                y = 1;
            end
            delete([app.perfil_h_fig,app.perfil_v_fig,app.linea_px,app.linea_py,app.linea_py_perfil,app.linea_px_perfil]) %actualizamos la figura
            app.perfil_h_fig = plot(app.UIAxes3,app.img(y,:));
            app.perfil_v_fig = plot(app.UIAxes4,app.img(:,x));
            app.linea_px_perfil = xline(app.UIAxes3,x,"HitTest","off"); % "HitTest","off" permite realizar clic sobre el elemento grafico
            app.linea_py_perfil = xline(app.UIAxes4,y,"HitTest","off");
            app.linea_px =  xline(app.UIAxes, x,'Color',[51/255,1,1],'linewidth',1.2);
            app.linea_py =  yline(app.UIAxes, y,'Color',[51/255,1,1],'linewidth',1.2);
        end
        
        function [] = graficar_error(app,index_left1_right2_2,mean_locs)
            delete(app.error_grafica)
            distancia = index_left1_right2_2(2,:,:) - index_left1_right2_2(1,:,:)+1;
            dis_promedio = mean(distancia);
            abs_dif = abs(distancia - dis_promedio);
            error_promedio = mean(abs_dif);
            app.desviacion_es = std(abs_dif);
            app.error_grafica = errorbar(app.UIAxes2,error_promedio(:),app.desviacion_es(:),'-b');
            % muestra los resultados
            % ordenamos los valores de mas pequeño al mas alto
            [app.desv_sort,app.desv_loc] = sort(app.desviacion_es);
            app.ResultadosListBox.Items = {['[Desv. max.1, loc] = [',num2str(app.desviacion_es(app.desv_loc(end)),'%.4f'),',',num2str(app.desv_loc(end)),']'],...
                ['[Desv. max.2, loc] = [',num2str(app.desviacion_es(app.desv_loc(end-1)),'%.4f'),',',num2str(app.desv_loc(end-1)),']'],...
                ['mean(Desv.) = ',num2str(mean(app.desviacion_es),'%.4f')]};
            app.ResultadosListBox.ItemsData = [1 2 3];
            pos_texto = mean((index_left1_right2_2(2,:,:)+index_left1_right2_2(1,:,:))/2)-3;
            text(app.UIAxes,[pos_texto(app.desv_loc(end));pos_texto(app.desv_loc(end-1))],[mean_locs(1)-10;mean_locs(1)-10], ...
                cellstr(num2str([app.desv_loc(end);app.desv_loc(end-1)])),'Color','m')
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.salida = "Esperando imagen DICOM... Pulse Abrir para seleccionar el estudio.";
            app.outputTextArea.Value = app.salida;
            app.directorio = pwd;
            app.DirectorioEditField.Value = app.directorio;
        end

        % Button pushed function: AbrirButton
        function AbrirButtonPushed(app, event)
            [app.archivo,app.directorio] = uigetfile({'*.*;*.dcm'}, 'Seleccione su estudio DICOM');
            if not(app.directorio==0)
                % reiniciamos variables para la nueva imagen
                % desactivamos opciones para evitar errores
                app.DirectorioEditField.Value = app.directorio;
                delete([app.img_fig, ...
                    app.perfil_h_fig,app.perfil_v_fig,app.linea_px,app.linea_py,app.linea_py_perfil,app.linea_px_perfil, ...
                    app.error_grafica]) %actualizamos la figura
                app.ResultadosListBox.Items = {'Esperando analisis...'};
                app.IniciaranlisisButton.Enable = "off";
                app.CrearreportepdfButton.Enable = "off";
                app.GuardarImgButton.Enable = "off";
                app.clic_on = false;
                app.elekta_true = false;  
                app.varian_true = false;
                if isempty(dicomread(fullfile(app.directorio,app.archivo)))
                    app.CargarimagenButton.Enable = "off";
                else
                    app.CargarimagenButton.Enable = "on";
                end
            end
                
        end

        % Button pushed function: CargarimagenButton
        function CargarimagenButtonPushed(app, event)
            app.img_info = dicominfo(fullfile(app.directorio,app.archivo));
            app.salida = "[OK] Imagen cargada: "+ convertCharsToStrings(app.archivo)+newline+app.salida;
            app.outputTextArea.Value = app.salida;
            if contains(app.img_info.Manufacturer,'IMPAC Medical Systems, Inc.')
                title(app.UIAxes, 'Imagen Varian')
                app.salida = "Estudio: Varian" +newline+app.salida;
                app.elekta_true = false;  
                app.varian_true = true;
                app.outputTextArea.Value = app.salida;
            elseif contains(app.img_info.Manufacturer,'ELEKTA')
                title(app.UIAxes, 'Imagen Elekta')
                app.salida = "Estudio: Elekta" +newline+app.salida;
                app.outputTextArea.Value = app.salida;
                app.elekta_true = true;  
                app.varian_true = false;
            else
                app.salida = "[X] Imagen DICOM no compatible. " + ...
                    "El estudio seleccionado no contiene los caracteres" + ...
                    " IMPAC Medical Systems, Inc. o ELEKTA en sus metadatos."+newline+app.salida;
                app.outputTextArea.Value = app.salida;
            end
            
            if app.varian_true || app.elekta_true
                app.img = double(dicomread(app.img_info));
                app.img_8bit = uint8(255*ind2rgb(app.img, gray(2^16 -1))); % tiene 3 canales de color
                app.img_fig = imagesc(app.UIAxes,app.img_8bit,"HitTest","off",[0 255]);colormap(app.UIAxes,"gray");
                app.UIAxes.YDir = 'reverse';
                app.salida = "Se convirtio el tipo de dato de 16 a 8 bits" +newline+app.salida;
                app.outputTextArea.Value = app.salida;
                app.UIAxes.YLim = [0 app.img_info.Height];
                app.UIAxes.XLim = [0 app.img_info.Width];
                app.UIAxes.PlotBoxAspectRatio = [app.img_info.Width/app.img_info.Height, 1, 1];
                %%
                app.px = app.img_info.Width/2;
                app.py = app.img_info.Height/2;
                app.UIAxes3.XLim = [0 app.img_info.Width];
                app.UIAxes4.XLim = [0 app.img_info.Height];
                perfiles(app,app.px,app.py)
                app.clic_on = true;
                %%
                app.IniciaranlisisButton.Enable = "on";
                app.VerimagenoriginalCheckBox.Enable = "off";
                app.VerimagenoriginalCheckBox.Value = false;
            end
        end

        % Button down function: UIAxes
        function UIAxesButtonDown(app, event)
             if app.clic_on
                 P = get(app.UIAxes,'CurrentPoint'); 
                 app.px = P(1,1); app.py = P(1,2);
                 perfiles(app,app.px,app.py)
             end
        end

        % Button pushed function: IniciaranlisisButton
        function IniciaranlisisButtonPushed(app, event)
            app.clic_on = false;
            set(findobj(app.PruebaPicketFenceUIFigure,'Type','uibutton'),'Enable','off')
            pause(0.5)
            app.salida = "Iniciando analisis." +newline+app.salida;
            app.outputTextArea.Value = app.salida;
            drawnow('limitrate')
            if app.elekta_true
                %% ELEKTA
                %% buscamos el promedio de las filas en la variable img
                pause(0.5)
                app.salida = "Buscando maximos de los perfiles promedio horizontales." +newline+app.salida;
                app.outputTextArea.Value = app.salida;
                drawnow('limitrate')
                promedio = mean(rot90(app.img));
                % localizamos los máximos y su posición
                offset = 14;
                [~,mean_locs] = findpeaks(promedio,1:length(promedio), 'MinPeakHeight',10000, 'MinPeakDistance',20);
                mean_locs = mean_locs-offset;
                %% buscamos los puntos máximos por fila tomando un espacio de mas/menos (mean_locs(2)-mean_locs(1))/2 pixeles fijo para cada elemento en mean_locs
                pause(0.5)
                app.salida = "Suavizando perfiles." +newline+app.salida;
                app.outputTextArea.Value = app.salida;
                drawnow('limitrate')
                curva_ajustada = zeros(length(mean_locs),size(app.img,2));
                curva_ajustada_centrada = zeros(length(mean_locs),size(app.img,2));
                % suavizamos con un filtro de convolucion Gaussiano de 3x3
                img_gauss = imfilter(imadjust(imcomplement(uint16(app.img)),[],[],1.2),fspecial('gaussian',3),'same');
                llave = 1;
                for n = 1:length(mean_locs)
                    franja = double(img_gauss(mean_locs(n),:));
                    suavizado = smooth(franja,0.25,'rloess')';
                    curva_ajustada(n,:) = franja-suavizado+100;
                    %%
                    franja_c = double(img_gauss(mean_locs(n)+offset,:));
                    suavizado_c = smooth(franja_c,0.25,'rloess')';
                    curva_ajustada_centrada(n,:) = franja_c-suavizado_c+20;
                    [max_val,locs] = findpeaks(curva_ajustada(n,:),1:length(curva_ajustada(n,:)), 'MinPeakHeight',50, 'MinPeakDistance',15);
                    if llave
                        % asumimos que durante todo el ciclo length(locs) es el mismo
                        llave = 0;
                        max_locs = zeros(length(mean_locs),length(locs));
                        max_peak = zeros(length(mean_locs),length(locs));
                    end
                    max_locs(n,:) = locs;
                    max_peak(n,:) = max_val;
                end
                %% FMWH
                pause(0.5)
                app.salida = "Calculando distancia entre hojas por FMWH." +newline+app.salida;
                app.outputTextArea.Value = app.salida;
                drawnow('limitrate')
                d = zeros(length(mean_locs),length(max_locs(1,:)) - 1);
                index_left1_right2 = zeros(2,length(mean_locs),length(max_peak(1,:)));
                curva_ajustada = curva_ajustada_centrada;
                FMWH = (80/100);
                for k = 1:length(mean_locs)
                    %halfMaxValue = max_peak(k,:)*(50/100);
                    for n = 1:length(max_locs(k,:))
                        if n < length(max_locs(1,:))
                            d(k,n) = max_locs(k,n+1)-max_locs(k,n);
                        end
                        if n == 1
                            dis = round(d(k,1)/2);
                            halfMaxValue = max(curva_ajustada(k,max_locs(k,n)-dis:max_locs(k,n)+dis))*FMWH;
                            vec = curva_ajustada(k,max_locs(k,n)-dis:max_locs(k,n)+dis);
                            index_left1_right2(1,k,n) = find(vec >= halfMaxValue, 1, 'first')+max_locs(k,n)-dis-1;
                            index_left1_right2(2,k,n) = find(vec >= halfMaxValue, 1, 'last')+max_locs(k,n)-dis-1;
                        elseif (n <= length(max_locs(1,:))-1)&&(n >= 2)
                            dis = round(min([d(k,n),d(k,n-1)])/2);
                            halfMaxValue = max(curva_ajustada(k,max_locs(k,n)-dis:max_locs(k,n)+dis))*FMWH;
                            vec = curva_ajustada(k,max_locs(k,n)-dis:max_locs(k,n)+dis);
                            index_left1_right2(1,k,n) = find(vec >= halfMaxValue, 1, 'first')+max_locs(k,n)-dis-1;
                            index_left1_right2(2,k,n) = find(vec >= halfMaxValue, 1, 'last')+max_locs(k,n)-dis-1;
                        else % ultimo valor de n
                            dis = round(d(k,length(max_locs(k,:))-1)/2);
                            
                            l = max_locs(k,n)-dis;
                            r = max_locs(k,n)+dis;
                            if r > length(franja)
                                r =  length(franja);
                            end
                            halfMaxValue = max(curva_ajustada(k,l:r))*FMWH;
                            vec = curva_ajustada(k,l:r);
                            index_left1_right2(1,k,n) = find(vec >= halfMaxValue, 1, 'first')+max_locs(k,n)-dis-1;
                            index_left1_right2(2,k,n) = find(vec >= halfMaxValue, 1, 'last')+max_locs(k,n)-dis-1;
                        end    
                    end
                end
                %% FMWH 2
                pause(0.5)
                app.salida = "Calculando longitud de las hojas por FMWH." +newline+app.salida;
                app.outputTextArea.Value = app.salida;
                drawnow('limitrate')
                index_left1_right2_2 = zeros(2,length(mean_locs),1+length(max_peak(1,:)));
                % buscamos la separacion promedio entre el vector mean_locs
                %sep_media = mean_locs+offset;
                %for n = 1:length(mean_locs)-1
                %    sep_media(n) = mean_locs(n+1)-mean_locs(n);
                %end
                %sep_media=round(mean(sep_media)/2)-1;
                mean_locs_hojas = mean_locs + offset;
                img_c = double(app.img);
                % buscamos la localizacion de los valores medios
                for k = 1:length(mean_locs_hojas)
                    c1 = double(img_c(mean_locs(k),:));
                    c2 = smooth(c1,0.25,'rloess')';
                    perfil = c1 - c2 + 200; 
                    for n = 1:length(max_locs(k,:))+1
                        if n == 1
                            inicio = 1; final = max_locs(k,n);
                            vec = perfil(inicio:final);
                            halfMaxValue = max(vec)/2;
                            index_left1_right2_2(1,k,n) = find(vec >= halfMaxValue, 1, 'first')+inicio-1;
                            index_left1_right2_2(2,k,n) = find(vec >= halfMaxValue, 1, 'last')+inicio-1;
                        elseif (n <= length(max_locs(1,:)))&&(n >= 2)
                            inicio = max_locs(k,n-1); final = max_locs(k,n);
                            vec = perfil(inicio:final);
                            halfMaxValue = max(vec)/2;
                            index_left1_right2_2(1,k,n) = find(vec >= halfMaxValue, 1, 'first')+inicio-1;
                            index_left1_right2_2(2,k,n) = find(vec >= halfMaxValue, 1, 'last')+inicio-1;
                        else % ultimo valor de n
                            inicio = max_locs(k,n-1); final = size(app.img,2);
                            vec = perfil(inicio:final);
                            halfMaxValue = max(vec)/2;
                            index_left1_right2_2(1,k,n) = find(vec >= halfMaxValue, 1, 'first')+inicio-1;
                            index_left1_right2_2(2,k,n) = find(vec >= halfMaxValue, 1, 'last')+inicio-1;
                        end
                            
                    end
                end
                
                %% agregamos las capas de la imagen
                pause(0.5)
                app.img_8bit = imadjust(app.img_8bit,[],[],6.5);
                app.salida = "Agregando capas a la imagen." +newline+app.salida;
                app.outputTextArea.Value = app.salida;
                drawnow('limitrate')
                % capa 1: Lineas horizontales
                for n = 1:length(mean_locs)
                    % linea Azul R=0,G=0,B=255
                    loc1 = mean_locs(n)-1;
                    loc2 = mean_locs(n)+1;
                    app.img_8bit(loc1:loc2,:,1) = 0;
                    app.img_8bit(loc1:loc2,:,2) = 0;
                    app.img_8bit(loc1:loc2,:,3) = 255;
                end
                % actualizamos imagen
                pause(0.5)
                delete(app.img_fig)
                app.img_fig = imagesc(app.UIAxes,app.img_8bit,"HitTest","off",[0 255]);
                drawnow('limitrate')
                % capa 2: separacion entre hojas
                for k =1:length(max_locs(1,:))
                    % lineas Amarillas R=255,G=255,B=0
                    for n = 1:length(mean_locs)
                        indx1 = index_left1_right2(1,n,k);
                        indx2 = index_left1_right2(2,n,k);
                        loc1 = mean_locs(n)-3;
                        loc2 = mean_locs(n)+3;
                        app.img_8bit(loc1:loc2,indx1:indx2,1) = 255; 
                        app.img_8bit(loc1:loc2,indx1:indx2,2) = 255;
                        app.img_8bit(loc1:loc2,indx1:indx2,3) = 0;
                    end
                end
                % actualizamos imagen
                pause(0.5)
                delete(app.img_fig)
                app.img_fig = imagesc(app.UIAxes,app.img_8bit,"HitTest","off",[0 255]);
                drawnow('limitrate')
                % capa 3: perfil de hojas
                for k =1:length(max_locs(1,:))+1
                    % lineas Verdes R=0,G=255,B=0
                    for n = 1:length(mean_locs_hojas)
                        indx1 = index_left1_right2_2(1,n,k);
                        indx2 = index_left1_right2_2(2,n,k);
                        loc1 = mean_locs_hojas(n)-1;
                        loc2 = mean_locs_hojas(n)+1;
                        app.img_8bit(loc1:loc2,indx1:indx2,1) = 0; 
                        app.img_8bit(loc1:loc2,indx1:indx2,2) = 255;
                        app.img_8bit(loc1:loc2,indx1:indx2,3) = 0;
                    end
                end
                % actualizamos imagen
                pause(0.5)
                delete(app.img_fig)
                app.img_fig = imagesc(app.UIAxes,app.img_8bit,"HitTest","off",[0 255]);
                drawnow('limitrate')
                %% graficamos el error
                pause(0.5)
                app.salida = "Realizando calculo de estadisticas." +newline+app.salida;
                app.outputTextArea.Value = app.salida;
                drawnow('limitrate')
                graficar_error(app,index_left1_right2_2,mean_locs)
            elseif app.varian_true
                %% varian
                %% buscamos el promedio de las filas en la variable img
                pause(0.5)
                app.salida = "Buscando maximos de los perfiles promedio horizontales." +newline+app.salida;
                app.outputTextArea.Value = app.salida;
                drawnow('limitrate')
                promedio = mean(rot90(app.img));
                % localizamos los máximos y su posición
                [~,mean_locs] = findpeaks(promedio,1:length(promedio), 'MinPeakHeight',10000, 'MinPeakDistance',20);                
                %% buscamos los puntos máximos por fila tomando un espacio de mas/menos (mean_locs(2)-mean_locs(1))/2 pixeles fijo para cada elemento en mean_locs
                pause(0.5)
                app.salida = "Suavizando perfiles." +newline+app.salida;
                app.outputTextArea.Value = app.salida;
                drawnow('limitrate')

                delta = (mean_locs(2)-mean_locs(1))/2;
                curva_ajustada = zeros(length(mean_locs),size(app.img,2));
                llave = 1;
                for n = 1:length(mean_locs)
                    franja = app.img(mean_locs(n)-delta:mean_locs(n)+delta,:);
                    promedio = mean(franja);
                    suavizado = smooth(promedio,0.25,'rloess')';
                    curva_ajustada(n,:) = promedio-suavizado;
                    [max_val,locs] = findpeaks(curva_ajustada(n,:),1:length(curva_ajustada(n,:)), 'MinPeakHeight',500, 'MinPeakDistance',10);
                    if llave
                        % asumimos que durante todo el ciclo length(locs) es el mismo
                        llave = 0;
                        max_locs = zeros(length(mean_locs),length(locs));
                        max_peak = zeros(length(mean_locs),length(locs));
                    end
                    max_locs(n,:) = locs;
                    max_peak(n,:) = max_val;
                end
                %% FMWH
                pause(0.5)
                app.salida = "Calculando distancia entre hojas por FMWH." +newline+app.salida;
                app.outputTextArea.Value = app.salida;
                drawnow('limitrate')
                % vector de disctancias de un máximo al sig. máximo
                d = zeros(length(mean_locs),length(max_locs(1,:)) - 1);
                index_left1_right2 = zeros(2,length(mean_locs),length(max_peak(1,:)));
                for k = 1:length(mean_locs)
                    halfMaxValue = max_peak(k,:)/2;
                    for n = 1:length(max_locs(k,:))
                        if n < length(max_locs(1,:))
                            d(k,n) = max_locs(k,n+1)-max_locs(k,n);
                        end
                        if n == 1
                            dis = round(d(k,1)/2);
                            vec = curva_ajustada(k,max_locs(k,n)-dis:max_locs(k,n)+dis);
                            index_left1_right2(1,k,n) = find(vec >= halfMaxValue(n), 1, 'first')+max_locs(k,n)-dis-1;
                            index_left1_right2(2,k,n) = find(vec >= halfMaxValue(n), 1, 'last')+max_locs(k,n)-dis-1;
                        elseif (n <= length(max_locs(1,:))-1)&&(n >= 2)
                            dis = round(min([d(k,n),d(k,n-1)])/2);
                            vec = curva_ajustada(k,max_locs(k,n)-dis:max_locs(k,n)+dis);
                            index_left1_right2(1,k,n) = find(vec >= halfMaxValue(n), 1, 'first')+max_locs(k,n)-dis-1;
                            index_left1_right2(2,k,n) = find(vec >= halfMaxValue(n), 1, 'last')+max_locs(k,n)-dis-1;
                        else % ultimo valor de n
                            dis = round(d(k,length(max_locs(k,:))-1)/2);
                            vec = curva_ajustada(k,max_locs(k,n)-dis:max_locs(k,n)+dis);
                            index_left1_right2(1,k,n) = find(vec >= halfMaxValue(n), 1, 'first')+max_locs(k,n)-dis-1;
                            index_left1_right2(2,k,n) = find(vec >= halfMaxValue(n), 1, 'last')+max_locs(k,n)-dis-1;
                        end
                            
                    end
                end
                %% FMWH 2
                pause(0.5)
                app.salida = "Calculando longitud de las hojas por FMWH." +newline+app.salida;
                app.outputTextArea.Value = app.salida;
                drawnow('limitrate')
                index_left1_right2_2 = zeros(2,length(mean_locs),1+length(max_peak(1,:)));
                % buscamos la separacion promedio entre el vector mean_locs
                sep_media = zeros(1,length(mean_locs)-1);
                for n = 1:length(mean_locs)-1
                    sep_media(n) = mean_locs(n+1)-mean_locs(n);
                end
                sep_media=round(mean(sep_media)/2)-1;
                mean_locs_hojas = mean_locs + sep_media;
                img_c = double(imcomplement(app.img));
                % buscamos la localizacion de los valores medios
                for k = 1:length(mean_locs_hojas)
                    c1 = double(img_c(mean_locs_hojas(k),:));
                    c2 = smooth(c1,0.25,'rloess')'-2000;
                    perfil = c1 - c2; 
                    for n = 1:length(max_locs(k,:))+1
                        if n == 1
                            inicio = 1; final = max_locs(k,n);
                            vec = perfil(inicio:final);
                            halfMaxValue = max(vec)/2;
                            index_left1_right2_2(1,k,n) = find(vec >= halfMaxValue, 1, 'first')+inicio-1;
                            index_left1_right2_2(2,k,n) = find(vec >= halfMaxValue, 1, 'last')+inicio-1;
                        elseif (n <= length(max_locs(1,:)))&&(n >= 2)
                            inicio = max_locs(k,n-1); final = max_locs(k,n);
                            vec = perfil(inicio:final);
                            halfMaxValue = max(vec)/2;
                            index_left1_right2_2(1,k,n) = find(vec >= halfMaxValue, 1, 'first')+inicio-1;
                            index_left1_right2_2(2,k,n) = find(vec >= halfMaxValue, 1, 'last')+inicio-1;
                        else % ultimo valor de n
                            inicio = max_locs(k,n-1); final = size(app.img,2);
                            vec = perfil(inicio:final);
                            halfMaxValue = max(vec)/2;
                            index_left1_right2_2(1,k,n) = find(vec >= halfMaxValue, 1, 'first')+inicio-1;
                            index_left1_right2_2(2,k,n) = find(vec >= halfMaxValue, 1, 'last')+inicio-1;
                        end
                            
                    end
                end
                %% agregamos las capas de la imagen
                pause(0.5)
                app.salida = "Agregando capas a la imagen." +newline+app.salida;
                app.outputTextArea.Value = app.salida;
                drawnow('limitrate')
                % capa 1: Lineas horizontales
                for n = 1:length(mean_locs)
                    % linea Azul R=0,G=0,B=255
                    loc1 = mean_locs(n)-1;
                    loc2 = mean_locs(n)+1;
                    app.img_8bit(loc1:loc2,:,1) = 0;
                    app.img_8bit(loc1:loc2,:,2) = 0;
                    app.img_8bit(loc1:loc2,:,3) = 255;
                end
                % actualizamos imagen
                pause(0.5)
                delete(app.img_fig)
                app.img_fig = imagesc(app.UIAxes,app.img_8bit,"HitTest","off",[0 255]);
                drawnow('limitrate')
                % capa 2: separacion entre hojas
                for k =1:length(max_locs(1,:))
                    % lineas Amarillas R=255,G=255,B=0
                    for n = 1:length(mean_locs)
                        indx1 = index_left1_right2(1,n,k);
                        indx2 = index_left1_right2(2,n,k);
                        loc1 = mean_locs(n)-1;
                        loc2 = mean_locs(n)+1;
                        app.img_8bit(loc1:loc2,indx1:indx2,1) = 255; 
                        app.img_8bit(loc1:loc2,indx1:indx2,2) = 255;
                        app.img_8bit(loc1:loc2,indx1:indx2,3) = 0;
                    end
                end
                % actualizamos imagen
                pause(0.5)
                delete(app.img_fig)
                app.img_fig = imagesc(app.UIAxes,app.img_8bit,"HitTest","off",[0 255]);
                drawnow('limitrate')
                % capa 3: perfil de hojas
                for k =1:length(max_locs(1,:))+1
                    % lineas Verdes R=0,G=255,B=0
                    for n = 1:length(mean_locs_hojas)
                        indx1 = index_left1_right2_2(1,n,k);
                        indx2 = index_left1_right2_2(2,n,k);
                        loc1 = mean_locs_hojas(n)-1;
                        loc2 = mean_locs_hojas(n)+1;
                        app.img_8bit(loc1:loc2,indx1:indx2,1) = 0; 
                        app.img_8bit(loc1:loc2,indx1:indx2,2) = 255;
                        app.img_8bit(loc1:loc2,indx1:indx2,3) = 0;
                    end
                end
                % actualizamos imagen
                pause(0.5)
                delete(app.img_fig)
                app.img_fig = imagesc(app.UIAxes,app.img_8bit,"HitTest","off",[0 255]);
                drawnow('limitrate')
                %% graficamos el error
                pause(0.5)
                app.salida = "Realizando calculo de estadisticas." +newline+app.salida;
                app.outputTextArea.Value = app.salida;
                drawnow('limitrate')
                graficar_error(app,index_left1_right2_2,mean_locs)
            end
            pause(0.5)
            app.salida = "Analisis terminado." +newline+app.salida;
            app.outputTextArea.Value = app.salida;
            drawnow('limitrate')
            %%
            set(findobj(app.PruebaPicketFenceUIFigure,'Type','uibutton'),'Enable','on')
            app.clic_on = true;
            perfiles(app,app.px,app.py)
        end

        % Value changed function: VerimagenoriginalCheckBox
        function VerimagenoriginalCheckBoxValueChanged(app, event)
            %app.VerimagenoriginalCheckBox.Value;
            if app.VerimagenoriginalCheckBox.Value
                delete(app.img_fig)
                app.img_fig = imagesc(app.UIAxes,uint8(255*ind2rgb(app.img, gray(2^16 -1))),"HitTest","off",[0 255]);colormap(app.UIAxes,"gray");
            else
                delete(app.img_fig)
                app.img_fig = imagesc(app.UIAxes,app.img_8bit,"HitTest","off",[0 255]);
            end
            % dibujamos los perfiles
            perfiles(app,app.px,app.py)
        end

        % Button pushed function: CerrarButton
        function CerrarButtonPushed(app, event)
            app.delete
        end

        % Button pushed function: GuardarImgButton
        function GuardarImgButtonPushed(app, event)
            app.GuardarImgButton.Enable = "off";
            directorio_nuevo = fullfile(app.directorio,'PF_guardados');
            if ~exist(directorio_nuevo, 'dir')
               mkdir(directorio_nuevo);
               app.output = "[!] Directorio >PF_guardados< no encontrado, creando directorio en " + convertCharsToStrings(app.directorio) + newline + app.salida;
               app.outputTextArea.Value = app.salida;
            else
               app.salida = "[OK] Directorio >PF_guardados< encontrado en " + convertCharsToStrings(app.directorio) + newline + app.salida;
               app.outputTextArea.Value = app.salida;
            end
            if app.varian_true
                acelerador_nombre = 'Varian';
            elseif app.elekta_true
                acelerador_nombre = 'Elekta';
            end
            img_dir = fullfile(directorio_nuevo,[acelerador_nombre,'_',char(datetime('now','TimeZone','local','Format','d_MMM_y_HH_mm_ss_ms')),'.png']);
            imwrite(app.img_8bit, img_dir);
            app.salida = "[OK] Imagen guardada como: " + convertCharsToStrings(img_dir) + newline + app.salida;
            app.outputTextArea.Value = app.salida;
            pause(0.5)
            app.GuardarImgButton.Enable = "on";
        end

        % Button pushed function: CrearreportepdfButton
        function CrearreportepdfButtonPushed(app, event)
            set(findobj(app.PruebaPicketFenceUIFigure,'Type','uibutton'),'Enable','off')
            app.salida = "Generando reporte..."  + newline + app.salida;
            app.outputTextArea.Value = app.salida;
            %%
            app.salida = "Importando librerias."  + newline + app.salida;
            app.outputTextArea.Value = app.salida;
            import mlreportgen.dom.*
            import mlreportgen.report.*
            %%
            if app.varian_true
                acelerador_nombre = 'Varian';
            elseif app.elekta_true
                acelerador_nombre = 'Elekta';
            end
            doc = Report(['reporte_',acelerador_nombre,'_',char(datetime('now','TimeZone','local','Format','d_MMM_y_HH_mm_ss_ms'))],'pdf'); 
            %%
            img_portada_dir = fullfile('icon','portada.png');
            append(doc,Image(img_portada_dir));
            append(doc,"Resultados:");append(doc," ");
            append(doc,"Desviación máxima encontrada: "+num2str(app.desviacion_es(app.desv_loc(end)),'%.4f'));
            append(doc,"Segunda desviación máxima encontrada: "+num2str(app.desviacion_es(app.desv_loc(end-1)),'%.4f'));
            append(doc,"Desviación media: "+num2str(mean(app.desviacion_es),'%.4f'));
            append(doc," ");
            % guardamos la figura app.UIAxes en un archivo png en la carpeta cache
            % creamos la carpeta cache
            mkdir('cache');
            % guardamos las figuras
            img_dir = fullfile('cache','figura.jpg');
            img_dir1 = fullfile('cache','figura1.jpg');
            exportgraphics(app.UIAxes2,img_dir)
            imwrite(imresize(app.img_8bit,round((400/636)*[size(app.img_8bit,1),size(app.img_8bit,2)])), img_dir1);
            % cambiamos el tamaño de la imagen de tal menera que tenga un ancho de 400 pixeles
            img_cache = imread(img_dir);
            img_cache = imresize(img_cache,round((400/636)*[size(img_cache,1),size(img_cache,2)]));
            % guardamos la imagen en un archivo png
            imwrite(img_cache,img_dir);
            % agregamos la imagen al reporte
            append(doc,"                    Imagen resultante")
            append(doc,Image(img_dir1));
            append(doc," ");append(doc," ");
            % agregamos el grafico de error
            append(doc,Image(img_dir));
            append(doc," ");append(doc," ");
            %agregamos la tabla
            locs = app.desv_loc(:);
            desviacion = app.desv_sort(:);
            desvTabla = FormalTable(["Num. Lamina","Desviacion"],[locs,desviacion]);
            desvTabla.Header.Style{end+1} = BackgroundColor("silver");
            desvTabla.Width = "250pt";
            baseTabReporter = BaseTable(desvTabla);
            append(doc,baseTabReporter);
            append(doc," ");append(doc," ");
            append(doc,"Documento generado el día "+string(datetime));
            close(doc);
            %eliminamos la carpeta cache
            app.salida = "Borando cache..."  + newline + app.salida;
            app.outputTextArea.Value = app.salida;
            rmdir('cache','s');
            app.salida = "Reporte generado."  + newline + app.salida;
            app.outputTextArea.Value = app.salida;
            set(findobj(app.PruebaPicketFenceUIFigure,'Type','uibutton'),'Enable','on')
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create PruebaPicketFenceUIFigure and hide until all components are created
            app.PruebaPicketFenceUIFigure = uifigure('Visible', 'off');
            app.PruebaPicketFenceUIFigure.Position = [100 100 1098 628];
            app.PruebaPicketFenceUIFigure.Name = 'Prueba Picket Fence ';
            app.PruebaPicketFenceUIFigure.Icon = fullfile(pathToMLAPP, 'icon', 'fb_small.png');

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.PruebaPicketFenceUIFigure);
            title(app.UIAxes2, 'Error Promedio')
            xlabel(app.UIAxes2, 'Hoja')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.XGrid = 'on';
            app.UIAxes2.YGrid = 'on';
            app.UIAxes2.Position = [786 421 300 192];

            % Create UIAxes
            app.UIAxes = uiaxes(app.PruebaPicketFenceUIFigure);
            title(app.UIAxes, 'Seleccione su estudio DICOM')
            app.UIAxes.DataAspectRatio = [1 1 1];
            app.UIAxes.PlotBoxAspectRatio = [3 1 1];
            app.UIAxes.XTick = [];
            app.UIAxes.YTick = [];
            app.UIAxes.ButtonDownFcn = createCallbackFcn(app, @UIAxesButtonDown, true);
            app.UIAxes.Position = [1 183 768 446];

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.PruebaPicketFenceUIFigure);
            title(app.UIAxes3, 'Perfil Horizontal')
            xlabel(app.UIAxes3, 'Pixel')
            ylabel(app.UIAxes3, 'Intensidad')
            zlabel(app.UIAxes3, 'Z')
            app.UIAxes3.XGrid = 'on';
            app.UIAxes3.YGrid = 'on';
            app.UIAxes3.Position = [786 223 300 185];

            % Create UIAxes4
            app.UIAxes4 = uiaxes(app.PruebaPicketFenceUIFigure);
            title(app.UIAxes4, 'Perfil Vertical')
            xlabel(app.UIAxes4, 'Pixel')
            ylabel(app.UIAxes4, 'Intensidad')
            zlabel(app.UIAxes4, 'Z')
            app.UIAxes4.XGrid = 'on';
            app.UIAxes4.YGrid = 'on';
            app.UIAxes4.Position = [786 15 300 185];

            % Create AbrirButton
            app.AbrirButton = uibutton(app.PruebaPicketFenceUIFigure, 'push');
            app.AbrirButton.ButtonPushedFcn = createCallbackFcn(app, @AbrirButtonPushed, true);
            app.AbrirButton.Icon = fullfile(pathToMLAPP, 'icon', 'open.png');
            app.AbrirButton.Position = [449 146 76 23];
            app.AbrirButton.Text = 'Abrir';

            % Create CargarimagenButton
            app.CargarimagenButton = uibutton(app.PruebaPicketFenceUIFigure, 'push');
            app.CargarimagenButton.ButtonPushedFcn = createCallbackFcn(app, @CargarimagenButtonPushed, true);
            app.CargarimagenButton.Enable = 'off';
            app.CargarimagenButton.Position = [542 146 100 23];
            app.CargarimagenButton.Text = 'Cargar imagen';

            % Create DirectorioEditFieldLabel
            app.DirectorioEditFieldLabel = uilabel(app.PruebaPicketFenceUIFigure);
            app.DirectorioEditFieldLabel.HorizontalAlignment = 'right';
            app.DirectorioEditFieldLabel.Position = [11 147 56 22];
            app.DirectorioEditFieldLabel.Text = 'Directorio';

            % Create IniciaranlisisButton
            app.IniciaranlisisButton = uibutton(app.PruebaPicketFenceUIFigure, 'push');
            app.IniciaranlisisButton.ButtonPushedFcn = createCallbackFcn(app, @IniciaranlisisButtonPushed, true);
            app.IniciaranlisisButton.Icon = fullfile(pathToMLAPP, 'icon', 'run.png');
            app.IniciaranlisisButton.Enable = 'off';
            app.IniciaranlisisButton.Position = [608 96 146 34];
            app.IniciaranlisisButton.Text = 'Iniciar análisis';

            % Create DirectorioEditField
            app.DirectorioEditField = uieditfield(app.PruebaPicketFenceUIFigure, 'text');
            app.DirectorioEditField.Editable = 'off';
            app.DirectorioEditField.Position = [77 147 357 22];

            % Create CrearreportepdfButton
            app.CrearreportepdfButton = uibutton(app.PruebaPicketFenceUIFigure, 'push');
            app.CrearreportepdfButton.ButtonPushedFcn = createCallbackFcn(app, @CrearreportepdfButtonPushed, true);
            app.CrearreportepdfButton.Icon = fullfile(pathToMLAPP, 'icon', 'pdf.png');
            app.CrearreportepdfButton.Enable = 'off';
            app.CrearreportepdfButton.Position = [608 50 146 34];
            app.CrearreportepdfButton.Text = 'Crear reporte (.pdf)';

            % Create Image1
            app.Image1 = uiimage(app.PruebaPicketFenceUIFigure);
            app.Image1.Position = [11 16 36 51];
            app.Image1.ImageSource = fullfile(pathToMLAPP, 'icon', 'unam_logo.png');

            % Create Image2
            app.Image2 = uiimage(app.PruebaPicketFenceUIFigure);
            app.Image2.Position = [11 84 38 46];
            app.Image2.ImageSource = fullfile(pathToMLAPP, 'icon', 'fc.png');

            % Create outputTextArea
            app.outputTextArea = uitextarea(app.PruebaPicketFenceUIFigure);
            app.outputTextArea.FontColor = [0 1 0];
            app.outputTextArea.BackgroundColor = [0 0 0];
            app.outputTextArea.Position = [55 16 230 114];

            % Create CerrarButton
            app.CerrarButton = uibutton(app.PruebaPicketFenceUIFigure, 'push');
            app.CerrarButton.ButtonPushedFcn = createCallbackFcn(app, @CerrarButtonPushed, true);
            app.CerrarButton.Icon = fullfile(pathToMLAPP, 'icon', 'icon_close.png');
            app.CerrarButton.Position = [652 146 100 23];
            app.CerrarButton.Text = 'Cerrar';

            % Create GuardarImgButton
            app.GuardarImgButton = uibutton(app.PruebaPicketFenceUIFigure, 'push');
            app.GuardarImgButton.ButtonPushedFcn = createCallbackFcn(app, @GuardarImgButtonPushed, true);
            app.GuardarImgButton.Icon = fullfile(pathToMLAPP, 'icon', 'save.png');
            app.GuardarImgButton.Enable = 'off';
            app.GuardarImgButton.Position = [608 16 146 23];
            app.GuardarImgButton.Text = 'Guardar Img';

            % Create ResultadosListBoxLabel
            app.ResultadosListBoxLabel = uilabel(app.PruebaPicketFenceUIFigure);
            app.ResultadosListBoxLabel.HorizontalAlignment = 'right';
            app.ResultadosListBoxLabel.Position = [298 108 65 22];
            app.ResultadosListBoxLabel.Text = 'Resultados';

            % Create ResultadosListBox
            app.ResultadosListBox = uilistbox(app.PruebaPicketFenceUIFigure);
            app.ResultadosListBox.Items = {'Esperando analisis....'};
            app.ResultadosListBox.ItemsData = 1;
            app.ResultadosListBox.Position = [298 16 294 87];
            app.ResultadosListBox.Value = 1;

            % Create VerimagenoriginalCheckBox
            app.VerimagenoriginalCheckBox = uicheckbox(app.PruebaPicketFenceUIFigure);
            app.VerimagenoriginalCheckBox.ValueChangedFcn = createCallbackFcn(app, @VerimagenoriginalCheckBoxValueChanged, true);
            app.VerimagenoriginalCheckBox.Enable = 'off';
            app.VerimagenoriginalCheckBox.Text = 'Ver imagen original';
            app.VerimagenoriginalCheckBox.Position = [464 108 125 22];

            % Show the figure after all components are created
            app.PruebaPicketFenceUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Prueba_PF

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.PruebaPicketFenceUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.PruebaPicketFenceUIFigure)
        end
    end
end