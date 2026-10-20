-- =================== IMPORTACIONES ===================
local Enemigo = require("Enemigo")
local JugadorClass = require("Jugador")
local Habitacion = require("Habitacion")
local JefeClass = require("Jefe")
local Camera = require("camera") 
local Evento = require("Evento")
local HUDClass = require("HUD")

Texturas = {}
local ESCALA_MUNDO = 2
local InterfazHUD = nil

Juego = { gameover = false, victoria = false, enemigos = {}, puntaje = 0, sala_actual = 1 }
Opciones = { musica_on = true, volumen = 1.0, res_index = 1 }
local Resoluciones = { {800, 600}, {1024, 768}, {1280, 960} }

local MaquinaEstados = { estado_actual = nil }
function MaquinaEstados:Cambiar(nuevo_estado, params)
    if self.estado_actual and self.estado_actual.Salir then self.estado_actual:Salir() end
    self.estado_actual = nuevo_estado
    if self.estado_actual and self.estado_actual.Entrar then self.estado_actual:Entrar(params) end
end

-- =================== ESTADO: MENÚ INTERACTIVO ===================
local EstadoMenu = { botones = {} }
function EstadoMenu:Entrar()
    local sc = 0.3 
    self.botones = {
        { img = Texturas.btn_play, id = "play", y_offset = -100, base_scale = sc, scale = sc, target_scale = sc, accion = function() 
            Juego.puntaje = 0; Juego.sala_actual = 1; Evento.emit("reset_juego"); MaquinaEstados:Cambiar(EstadoJugando)
        end },
        { img = Texturas.btn_options, id = "options", y_offset = 0, base_scale = sc, scale = sc, target_scale = sc, accion = function() 
            MaquinaEstados:Cambiar(EstadoOpciones) 
        end },
        { img = Texturas.btn_exit, id = "exit", y_offset = 100, base_scale = sc, scale = sc, target_scale = sc, accion = function() love.event.quit() end },
        { img = Texturas.btn_info, id = "info", base_scale = 0.15, scale = 0.15, target_scale = 0.15, accion = function() print("Créditos: Juego creado por crack") end }
    }
end

function EstadoMenu:Update(dt)
    local mx, my = love.mouse.getPosition()
    local cx = love.graphics.getWidth() / 2
    local cy = love.graphics.getHeight() / 2
    
    for _, btn in ipairs(self.botones) do
        local bx, by
        if btn.id == "info" then
            bx = love.graphics.getWidth() - 40; by = love.graphics.getHeight() - 40
        else
            bx = cx; by = cy + btn.y_offset
        end
        btn.x = bx; btn.y = by
        
        local w = btn.img:getWidth() * btn.base_scale
        local h = btn.img:getHeight() * btn.base_scale
        if mx >= bx - w/2 and mx <= bx + w/2 and my >= by - h/2 and my <= by + h/2 then
            btn.target_scale = btn.base_scale * 1.15 
        else btn.target_scale = btn.base_scale end
        btn.scale = btn.scale + (btn.target_scale - btn.scale) * 15 * dt
    end
end

function EstadoMenu:Draw()
    love.graphics.setColor(1, 1, 1) 
    love.graphics.setFont(FuenteGrande)
    love.graphics.printf("DECA-RUN", 0, love.graphics.getHeight()/2 - 200, love.graphics.getWidth(), "center")
    for _, btn in ipairs(self.botones) do
        love.graphics.draw(btn.img, btn.x, btn.y, 0, btn.scale, btn.scale, btn.img:getWidth()/2, btn.img:getHeight()/2)
    end
end

function EstadoMenu:Mousepressed(x, y, button)
    if button == 1 then
        for _, btn in ipairs(self.botones) do
            local w = btn.img:getWidth() * btn.base_scale; local h = btn.img:getHeight() * btn.base_scale
            if x >= btn.x - w/2 and x <= btn.x + w/2 and y >= btn.y - h/2 and y <= btn.y + h/2 then btn.accion() end
        end
    end
end

-- =================== ESTADO: OPCIONES ===================
EstadoOpciones = { botones = {} }
function EstadoOpciones:Entrar()
    local sc = 0.3 
    self.botones = {
        { img = Texturas.btn_music, id = "music", y_offset = -70, base_scale = sc, scale = sc, target_scale = sc, accion = function() 
            Opciones.musica_on = not Opciones.musica_on
            love.audio.setVolume(Opciones.musica_on and Opciones.volumen or 0)
        end },
        { img = Texturas.btn_exit, id = "exit", y_offset = 180, base_scale = sc, scale = sc, target_scale = sc, accion = function() MaquinaEstados:Cambiar(EstadoMenu) end }
    }
end

function EstadoOpciones:Update(dt)
    local mx, my = love.mouse.getPosition()
    local cx = love.graphics.getWidth() / 2
    local cy = love.graphics.getHeight() / 2

    for _, btn in ipairs(self.botones) do
        btn.x = cx; btn.y = cy + btn.y_offset
        local w = btn.img:getWidth() * btn.base_scale
        local h = btn.img:getHeight() * btn.base_scale
        local by = btn.y -- <--- ESTA ERA LA VARIABLE QUE FALTABA
        
        if mx >= btn.x - w/2 and mx <= btn.x + w/2 and my >= by - h/2 and my <= by + h/2 then
            btn.target_scale = btn.base_scale * 1.15 
        else btn.target_scale = btn.base_scale end
        btn.scale = btn.scale + (btn.target_scale - btn.scale) * 15 * dt
    end

    if love.mouse.isDown(1) then
        local bx = cx - 50; local by_slider = cy + 20; local bw = 200
        if mx >= bx and mx <= bx + bw and my >= by_slider - 10 and my <= by_slider + 30 then
            Opciones.volumen = (mx - bx) / bw
            if Opciones.volumen < 0 then Opciones.volumen = 0 end
            if Opciones.volumen > 1 then Opciones.volumen = 1 end
            if Opciones.musica_on then love.audio.setVolume(Opciones.volumen) end
        end
    end
end
function EstadoOpciones:Draw()
    local cx = love.graphics.getWidth() / 2
    local cy = love.graphics.getHeight() / 2
    
    love.graphics.setColor(1, 1, 1) 
    love.graphics.setFont(FuenteGrande)
    love.graphics.printf("OPCIONES", 0, cy - 180, love.graphics.getWidth(), "center")
    
    for _, btn in ipairs(self.botones) do
        if btn.id == "music" and not Opciones.musica_on then love.graphics.setColor(0.4, 0.4, 0.4) else love.graphics.setColor(1, 1, 1) end
        love.graphics.draw(btn.img, btn.x, btn.y, 0, btn.scale, btn.scale, btn.img:getWidth()/2, btn.img:getHeight()/2)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(Texturas.btn_audio, cx - 120, cy + 20, 0, 0.25, 0.25, Texturas.btn_audio:getWidth()/2, Texturas.btn_audio:getHeight()/2)
    
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", cx - 50, cy + 10, 200, 20)
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", cx - 50, cy + 10, 200 * Opciones.volumen, 20)
    love.graphics.setColor(1, 1, 1)

    love.graphics.setFont(FuenteChica)
    love.graphics.printf("Resolucion: " .. Resoluciones[Opciones.res_index][1] .. "x" .. Resoluciones[Opciones.res_index][2] .. " (Clic para cambiar)", 0, cy + 100, love.graphics.getWidth(), "center")
end

function EstadoOpciones:Mousepressed(x, y, button)
    local cx = love.graphics.getWidth() / 2
    local cy = love.graphics.getHeight() / 2
    if button == 1 then
        for _, btn in ipairs(self.botones) do
            local w = btn.img:getWidth() * btn.base_scale; local h = btn.img:getHeight() * btn.base_scale
            if x >= btn.x - w/2 and x <= btn.x + w/2 and y >= btn.y - h/2 and y <= btn.y + h/2 then btn.accion() end
        end
        if x >= cx - 200 and x <= cx + 200 and y >= cy + 90 and y <= cy + 130 then
            Opciones.res_index = Opciones.res_index + 1
            if Opciones.res_index > 3 then Opciones.res_index = 1 end
            love.window.setMode(Resoluciones[Opciones.res_index][1], Resoluciones[Opciones.res_index][2])
        end
    end
end

-- =================== ESTADO: JUGANDO ===================
EstadoJugando = { habitacion = nil, jugador = nil, enemigos = {}, jefe = nil, camara = nil, estado_partida = "activo" }

function EstadoJugando:Entrar(params)
    local prohibido = params and params.lado_prohibido or 0
    self.habitacion = Habitacion:Nueva(15, 25, prohibido)
    
    local centro_x = (self.habitacion.ancho * self.habitacion.tam_tile) / 2
    local centro_y = (self.habitacion.alto * self.habitacion.tam_tile) / 2
    self.jugador = JugadorClass:Nuevo(centro_x, centro_y) 
    self.estado_partida = "activo"
    
    self.enemigos = {}
    self.jefe = nil

    if Juego.sala_actual == 10 then
        self.jefe = JefeClass:Nuevo(centro_x, centro_y - 100)
        Evento.emit("boss_hp", self.jefe.hp, self.jefe.max_hp)
    else
        self.enemigos = self.habitacion:GenerarEnemigos(Enemigo, self.jugador.x, self.jugador.y)
    end
    
    self.camara = Camera(self.jugador.x, self.jugador.y)
    self.camara.scale = ESCALA_MUNDO
end

function EstadoJugando:Update(dt)
    if self.estado_partida == "derrota" or self.estado_partida == "victoria_juego" then return end

    self.jugador:Actualizar(dt)
    
    local hit_x = self.jugador.x + self.jugador.hit_ox
    local hit_y = self.jugador.y + self.jugador.hit_oy
    local hit_w = self.jugador.hit_w
    local hit_h = self.jugador.hit_h

    self.limite_izq = self.habitacion.tam_tile - 15
    self.limite_der = (self.habitacion.ancho - 1) * self.habitacion.tam_tile + 15
    self.limite_arr = self.habitacion.tam_tile - 10
    self.limite_aba = (self.habitacion.alto - 1) * self.habitacion.tam_tile + 23

    local p_col = self.habitacion.puerta_col; local p_row = self.habitacion.puerta_row
    local p_x = p_col * self.habitacion.tam_tile; local p_y = p_row * self.habitacion.tam_tile
    local p_tam = self.habitacion.tam_tile

    if self.estado_partida == "victoria" then
        if p_col == 0 and hit_y < p_y + p_tam and hit_y + hit_h > p_y then self.limite_izq = -1000 end
        if p_col == self.habitacion.ancho - 1 and hit_y < p_y + p_tam and hit_y + hit_h > p_y then self.limite_der = 10000 end
        if p_row == 0 and hit_x < p_x + p_tam and hit_x + hit_w > p_x then self.limite_arr = -1000 end
        if p_row == self.habitacion.alto - 1 and hit_x < p_x + p_tam and hit_x + hit_w > p_x then self.limite_aba = 10000 end
    end

    if hit_x < self.limite_izq then self.jugador.x = self.limite_izq - self.jugador.hit_ox end
    if hit_x + hit_w > self.limite_der then self.jugador.x = self.limite_der - hit_w - self.jugador.hit_ox end
    if hit_y < self.limite_arr then self.jugador.y = self.limite_arr - self.jugador.hit_oy end
    if hit_y + hit_h > self.limite_aba then self.jugador.y = self.limite_aba - hit_h - self.jugador.hit_oy end
    
    local dx = self.jugador.x - self.camara.x
    local dy = self.jugador.y - self.camara.y
    self.camara:move(dx * 4 * dt, dy * 4 * dt)

    local enemigosVivos = 0
    local jx = self.jugador.x + self.jugador.hit_ox
    local jy = self.jugador.y + self.jugador.hit_oy

    if self.jefe then
        if self.jefe.vivo then
            enemigosVivos = enemigosVivos + 1
            self.jefe:Actualizar(dt, self.jugador.x, self.jugador.y, self.enemigos, Enemigo)
            
            local jfx = self.jefe.x + self.jefe.hit_ox; local jfy = self.jefe.y + self.jefe.hit_oy
            local jx_real = self.jugador.x + self.jugador.hit_ox
            local jy_real = self.jugador.y + self.jugador.hit_oy

            if hayColision(jx_real, jy_real, self.jugador.hit_w, self.jugador.hit_h, jfx, jfy, self.jefe.hit_w, self.jefe.hit_h) or 
               self.jefe:ComprobarAtaqueJugador(jx_real, jy_real, self.jugador.hit_w, self.jugador.hit_h) then
                if self.jugador:RecibirDano() and self.jugador.hp <= 0 then
                    self.estado_partida = "derrota"; Evento.emit("derrota")
                end
            end
        else
            self.estado_partida = "victoria_juego"
            Evento.emit("victoria_juego")
        end
    end

    -- Bucle de actualización con REPULSIÓN ENTRE ENEMIGOS para que no se superpongan
    for i, e1 in ipairs(self.enemigos) do
        if e1.vivo then
            enemigosVivos = enemigosVivos + 1
            e1:Actualizar(dt, self.jugador.x, self.jugador.y)
            
            -- Empuje entre enemigos (Evita superposición)
            for j, e2 in ipairs(self.enemigos) do
                if i ~= j and e2.vivo then
                    local dist_x, dist_y = e1.x - e2.x, e1.y - e2.y
                    local dist = math.sqrt(dist_x^2 + dist_y^2)
                    if dist < 25 and dist > 0.1 then
                        e1.x = e1.x + (dist_x / dist) * 40 * dt
                        e1.y = e1.y + (dist_y / dist) * 40 * dt
                    end
                end
            end

            local ex, ey = e1.x + e1.hit_ox, e1.y + e1.hit_oy
            if hayColision(jx, jy, self.jugador.hit_w, self.jugador.hit_h, ex, ey, e1.hit_w, e1.hit_h) then
                if self.jugador:RecibirDano() and self.jugador.hp <= 0 then
                    self.estado_partida = "derrota"; Evento.emit("derrota")
                end
            end
        end
    end
    
    if enemigosVivos == 0 and Juego.sala_actual < 10 then 
        if self.estado_partida ~= "victoria" then
            self.estado_partida = "victoria"; Evento.emit("sala_limpia")
        end
        
        InterfazHUD:ActualizarAngulo(self.jugador, p_x + p_tam/2, p_y + p_tam/2, self.camara)

        if hayColision(jx, jy, self.jugador.hit_w, self.jugador.hit_h, p_x, p_y, 32, 32) then
            Juego.sala_actual = Juego.sala_actual + 1
            Evento.emit("cambio_sala")
            local opuesto = {3, 4, 1, 2}
            MaquinaEstados:Cambiar(EstadoJugando, {lado_prohibido = opuesto[self.habitacion.lado_puerta]})
        end
    end
end

function EstadoJugando:Draw()
    self.camara:attach()
    self.habitacion:Dibujar(Texturas)
    self.jugador:Dibujar()
    
    if self.jefe and self.jefe.vivo then self.jefe:Dibujar() end

    -- Bucle de dibujo que prioriza y renderiza correctamente la animación de ataque
    for _, enemigo in ipairs(self.enemigos) do
        if enemigo.vivo then
            local frame = math.floor(enemigo.anim_index)
            local max_frames, quad, img
            
            if enemigo.atacando and #enemigo.quads_atacar > 0 then
                max_frames = #enemigo.quads_atacar
                if frame > max_frames then frame = max_frames end
                quad = enemigo.quads_atacar[frame]
                img = enemigo.img_atacar
            elseif enemigo.moviendose then
                max_frames = #enemigo.quads_mov
                if frame > max_frames then frame = max_frames end
                quad = enemigo.quads_mov[frame]
                img = enemigo.img_mov
            else
                max_frames = #enemigo.quads_quieto
                if frame > max_frames then frame = max_frames end
                quad = enemigo.quads_quieto[frame]
                img = enemigo.img_quieto
            end
            
            if quad and img then
                love.graphics.draw(img, quad, enemigo.x, enemigo.y)
            end
        end
    end
    self.camara:detach()
    InterfazHUD:Dibujar(self.jugador)
end

function EstadoJugando:Keypressed(key)
    if self.estado_partida == "activo" and key == "space" then
        self.jugador:Atacar(self.enemigos, self.jefe)
    elseif (self.estado_partida == "derrota" or self.estado_partida == "victoria_juego") and key == "r" then
        MaquinaEstados:Cambiar(EstadoMenu)
    elseif key == "9" then 
        Juego.sala_actual = 9
        self.enemigos = {} 
        self.estado_partida = "victoria"
        Evento.emit("sala_limpia")
    end
end

function hayColision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x2 < x1 + w1 and y1 < y2 + h2 and y2 < y1 + h1
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    FuenteGrande = love.graphics.newFont(36)
    FuenteChica = love.graphics.newFont(24) 

    Texturas.puerta = love.graphics.newImage("Sprites/Room/Puerta.png")
    Texturas.esquina = love.graphics.newImage("Sprites/Room/Esquina.png")
    Texturas.pared = love.graphics.newImage("Sprites/Room/Pared.png")
    Texturas.piso_medio1 = love.graphics.newImage("Sprites/Room/piso_medio1.png")
    Texturas.piso_medio2 = love.graphics.newImage("Sprites/Room/piso_medio2.png")
    Texturas.piso_medio3 = love.graphics.newImage("Sprites/Room/piso_medio3.png")
    
    Texturas.jugador_idle = love.graphics.newImage("Sprites/Player/Idle.png")
    Texturas.jugador_walk = love.graphics.newImage("Sprites/Player/Walk.png")
    Texturas.jugador_attack = love.graphics.newImage("Sprites/Player/Attack.png")
    
    Texturas.esqueleto_attack = love.graphics.newImage("Sprites/Enemies/Skeleton/Attack.png")
    Texturas.esqueleto_mov = love.graphics.newImage("Sprites/Enemies/Skeleton/Walk.png")
    Texturas.flyingeye_attack = love.graphics.newImage("Sprites/Enemies/Flying eye/Attack.png")
    Texturas.flyingeye_mov = love.graphics.newImage("Sprites/Enemies/Flying eye/Flight.png")
    Texturas.goblin_attack = love.graphics.newImage("Sprites/Enemies/Goblin/Attack.png")
    Texturas.goblin_mov = love.graphics.newImage("Sprites/Enemies/Goblin/Run.png")
    Texturas.mushroom_attack = love.graphics.newImage("Sprites/Enemies/Mushroom/Attack.png")
    Texturas.mushroom_mov = love.graphics.newImage("Sprites/Enemies/Mushroom/Run.png")
    
    Texturas.summon_quieto = love.graphics.newImage("Sprites/Boss/summonAppear.png")
    Texturas.summon_mov = love.graphics.newImage("Sprites/Boss/summonIdle.png")
    
    Texturas.boss_idle = love.graphics.newImage("Sprites/Boss/idle.png")
    Texturas.boss_walk = love.graphics.newImage("Sprites/Boss/idle.png")
    Texturas.boss_attack = love.graphics.newImage("Sprites/Boss/attacking.png")
    Texturas.boss_skill = love.graphics.newImage("Sprites/Boss/skill1.png")
    
    Texturas.btn_play = love.graphics.newImage("Sprites/Menu/Play Button.png")
    Texturas.btn_options = love.graphics.newImage("Sprites/Menu/Options Button.png")
    Texturas.btn_exit = love.graphics.newImage("Sprites/Menu/Exit Button.png")
    Texturas.btn_music = love.graphics.newImage("Sprites/Menu/Music Square Button.png")
    Texturas.btn_audio = love.graphics.newImage("Sprites/Menu/Audio Square Button.png")
    Texturas.btn_info = love.graphics.newImage("Sprites/Menu/Info Square Button.png")
    
    InterfazHUD = HUDClass:Nuevo()
    MaquinaEstados:Cambiar(EstadoMenu)
end

function love.update(dt) if MaquinaEstados.estado_actual then MaquinaEstados.estado_actual:Update(dt) end end
function love.draw() if MaquinaEstados.estado_actual then MaquinaEstados.estado_actual:Draw() end end
function love.keypressed(key) if MaquinaEstados.estado_actual and MaquinaEstados.estado_actual.Keypressed then MaquinaEstados.estado_actual:Keypressed(key) end end
function love.mousepressed(x, y, btn, ist, prs) if MaquinaEstados.estado_actual and MaquinaEstados.estado_actual.Mousepressed then MaquinaEstados.estado_actual:Mousepressed(x, y, btn) end end