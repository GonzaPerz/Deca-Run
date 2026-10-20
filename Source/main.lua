-- =================== IMPORTACIONES ===================
local Enemigo = require("Enemigo")
local JugadorClass = require("Jugador")
local Habitacion = require("Habitacion")
local Camera = require("camera") 

Texturas = {}
local ESCALA_MUNDO = 2

Juego = { gameover = false, victoria = false, enemigos = {}, puntaje = 0, sala_actual = 1 }

local MaquinaEstados = { estado_actual = nil }
function MaquinaEstados:Cambiar(nuevo_estado, params)
    if self.estado_actual and self.estado_actual.Salir then self.estado_actual:Salir() end
    self.estado_actual = nuevo_estado
    if self.estado_actual and self.estado_actual.Entrar then self.estado_actual:Entrar(params) end
end

-- =================== ESTADO: MENÚ ===================
local EstadoMenu = {}
function EstadoMenu:Entrar() end
function EstadoMenu:Update(dt) end
function EstadoMenu:Draw()
    love.graphics.setColor(1, 1, 1) -- <--- ESTA LÍNEA RESETEA EL COLOR
    love.graphics.setFont(FuenteGrande)
    love.graphics.printf("DECA-RUN", 0, 200, 800, "center")
    love.graphics.setFont(FuenteChica)
    love.graphics.printf("Presiona ENTER para Iniciar", 0, 300, 800, "center")
end
function EstadoMenu:Keypressed(key)
    if key == "return" then
        Juego.puntaje = 0
        Juego.sala_actual = 1
        MaquinaEstados:Cambiar(EstadoJugando)
    end
end

-- =================== ESTADO: JUGANDO ===================
EstadoJugando = {
    habitacion = nil, jugador = nil, enemigos = {},
    ---@type any
    camara = nil, estado_partida = "activo"
}

function EstadoJugando:Entrar(params)
    local prohibido = params and params.lado_prohibido or 0
    self.habitacion = Habitacion:Nueva(15, 25, prohibido)
    
    local centro_x = (self.habitacion.ancho * self.habitacion.tam_tile) / 2
    local centro_y = (self.habitacion.alto * self.habitacion.tam_tile) / 2
    self.jugador = JugadorClass:Nuevo(centro_x, centro_y) 
    
    self.enemigos = self.habitacion:GenerarEnemigos(Enemigo, self.jugador.x, self.jugador.y)
    self.estado_partida = "activo"
    
    self.camara = Camera(self.jugador.x, self.jugador.y)
    self.camara.scale = ESCALA_MUNDO
end

function EstadoJugando:Update(dt)
    if self.estado_partida == "derrota" then return end

    self.jugador:Actualizar(dt)
    
    -- =======================================================
    -- NUEVAS COLISIONES CON PAREDES Y PUERTA (Usando Hitbox Real)
    -- =======================================================
    local hit_x = self.jugador.x + self.jugador.hit_ox
    local hit_y = self.jugador.y + self.jugador.hit_oy
    local hit_w = self.jugador.hit_w
    local hit_h = self.jugador.hit_h

    -- ¡MODIFICÁ ESTOS NÚMEROS A OJO! (Valores negativos te dejan meterte en la pared)
    local ajuste_izq = -15  -- Deja que te metas 10 px en la pared izquierda
    local ajuste_der = 15   -- Deja que te metas 10 px en la pared derecha
    local ajuste_arr = -10  -- Clave: deja meter la cabeza en la pared de arriba
    local ajuste_aba = 23   -- Deja meter los pies en la pared de abajo

    -- Guardamos los límites en self para poder dibujarlos de color verde en pantalla
    self.limite_izq = self.habitacion.tam_tile + ajuste_izq
    self.limite_der = (self.habitacion.ancho - 1) * self.habitacion.tam_tile + ajuste_der
    self.limite_arr = self.habitacion.tam_tile + ajuste_arr
    self.limite_aba = (self.habitacion.alto - 1) * self.habitacion.tam_tile + ajuste_aba

    local p_col = self.habitacion.puerta_col
    local p_row = self.habitacion.puerta_row
    local p_x = p_col * self.habitacion.tam_tile
    local p_y = p_row * self.habitacion.tam_tile
    local p_tam = self.habitacion.tam_tile

    -- Abrir huecos si tocamos la puerta
    if self.estado_partida == "victoria" then
        if p_col == 0 and hit_y < p_y + p_tam and hit_y + hit_h > p_y then self.limite_izq = -1000 end
        if p_col == self.habitacion.ancho - 1 and hit_y < p_y + p_tam and hit_y + hit_h > p_y then self.limite_der = 10000 end
        if p_row == 0 and hit_x < p_x + p_tam and hit_x + hit_w > p_x then self.limite_arr = -1000 end
        if p_row == self.habitacion.alto - 1 and hit_x < p_x + p_tam and hit_x + hit_w > p_x then self.limite_aba = 10000 end
    end

    -- Empuje del jugador (usando la hitbox de sus pies)
    if hit_x < self.limite_izq then self.jugador.x = self.limite_izq - self.jugador.hit_ox end
    if hit_x + hit_w > self.limite_der then self.jugador.x = self.limite_der - hit_w - self.jugador.hit_ox end
    if hit_y < self.limite_arr then self.jugador.y = self.limite_arr - self.jugador.hit_oy end
    if hit_y + hit_h > self.limite_aba then self.jugador.y = self.limite_aba - hit_h - self.jugador.hit_oy end
    -- =======================================================
    
    local dx = self.jugador.x - self.camara.x
    local dy = self.jugador.y - self.camara.y
    self.camara:move(dx * 4 * dt, dy * 4 * dt)

    local enemigosVivos = 0
    local jx = self.jugador.x + self.jugador.hit_ox
    local jy = self.jugador.y + self.jugador.hit_oy

    for i, e1 in ipairs(self.enemigos) do
        if e1.vivo then
            enemigosVivos = enemigosVivos + 1
            e1:Actualizar(dt, self.jugador.x, self.jugador.y)
            
            for j, e2 in ipairs(self.enemigos) do
                if i ~= j and e2.vivo then
                    local dist_x, dist_y = e1.x - e2.x, e1.y - e2.y
                    local dist = math.sqrt(dist_x^2 + dist_y^2)
                    if dist < 20 and dist > 0.1 then
                        e1.x = e1.x + (dist_x / dist) * 40 * dt
                        e1.y = e1.y + (dist_y / dist) * 40 * dt
                    end
                end
            end
            
            local ex, ey = e1.x + e1.hit_ox, e1.y + e1.hit_oy
            if hayColision(jx, jy, self.jugador.hit_w, self.jugador.hit_h, ex, ey, e1.hit_w, e1.hit_h) then
                self.estado_partida = "derrota"
            end
        end
    end
    
    if enemigosVivos == 0 then 
        self.estado_partida = "victoria" 
        local puerta_x = self.habitacion.puerta_col * self.habitacion.tam_tile
        local puerta_y = self.habitacion.puerta_row * self.habitacion.tam_tile
        
        if hayColision(jx, jy, self.jugador.hit_w, self.jugador.hit_h, puerta_x, puerta_y, 32, 32) then
            Juego.sala_actual = Juego.sala_actual + 1
            local opuesto = {3, 4, 1, 2}
            MaquinaEstados:Cambiar(EstadoJugando, {lado_prohibido = opuesto[self.habitacion.lado_puerta]})
        end
    end
end

function EstadoJugando:Draw()
    self.camara:attach()
    self.habitacion:Dibujar(Texturas)
    self.jugador:Dibujar()
    
    for _, enemigo in ipairs(self.enemigos) do
        if enemigo.vivo then
            local frame = math.floor(enemigo.anim_index)
            local max_frames = enemigo.moviendose and #enemigo.quads_mov or #enemigo.quads_quieto
            if frame > max_frames then frame = max_frames end
            
            local quad = enemigo.moviendose and enemigo.quads_mov[frame] or enemigo.quads_quieto[frame]
            local img = enemigo.moviendose and enemigo.img_mov or enemigo.img_quieto
            
            if quad then
                love.graphics.draw(img, quad, enemigo.x, enemigo.y)
            end
        end
    end
    self.camara:detach()

    love.graphics.setFont(FuenteChica)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Puntaje: " .. Juego.puntaje, 15, 15, 770, "left")
    
    if Juego.sala_actual >= 10 then love.graphics.setColor(1, 0, 0) end
    love.graphics.printf("Sala: " .. Juego.sala_actual .. "/10", 0, 15, 785, "right")
    love.graphics.setColor(1, 1, 1)

    -- DIBUJO DE MENSAJES (VICTORIA / DERROTA)
    if self.estado_partida == "victoria" then
        love.graphics.setFont(FuenteGrande)
        love.graphics.setColor(0, 1, 0) -- Verde para sala limpia
        love.graphics.printf("¡SALA LIMPIADA! Avanza por la puerta", 0, 150, 800, "center")
        love.graphics.setColor(1, 1, 1) -- Resetea a blanco
    elseif self.estado_partida == "derrota" then 
        love.graphics.setFont(FuenteGrande)
        love.graphics.setColor(1, 0, 0) -- Rojo para Game Over
        love.graphics.printf("GAME OVER - Presiona R para reiniciar", 0, 250, 800, "center") 
        love.graphics.setColor(1, 1, 1) -- Resetea a blanco
    end
end

function EstadoJugando:Keypressed(key)
    if self.estado_partida == "activo" and key == "space" then
        self.jugador:Atacar(self.enemigos)
    elseif self.estado_partida == "derrota" and key == "r" then
        MaquinaEstados:Cambiar(EstadoMenu)
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
    
    -- CARGAMOS LAS IMÁGENES SEPARADAS DEL JUGADOR
    Texturas.jugador_idle = love.graphics.newImage("Sprites/Player/Idle.png")
    Texturas.jugador_walk = love.graphics.newImage("Sprites/Player/Walk.png")
    Texturas.jugador_attack = love.graphics.newImage("Sprites/Player/Attack.png")
    
    Texturas.slime_quieto = love.graphics.newImage("Sprites/Enemies/Slime_quieto.png")
    Texturas.slime_mov = love.graphics.newImage("Sprites/Enemies/Slime_moviendose.png")
    Texturas.esqueleto_quieto = love.graphics.newImage("Sprites/Enemies/Esqueleto_quieto.png")
    Texturas.esqueleto_mov = love.graphics.newImage("Sprites/Enemies/Esqueleto_moviendose.png")
    
    MaquinaEstados:Cambiar(EstadoMenu)
end

function love.update(dt)
    if MaquinaEstados.estado_actual then MaquinaEstados.estado_actual:Update(dt) end
end

function love.draw()
    if MaquinaEstados.estado_actual then MaquinaEstados.estado_actual:Draw() end
end

function love.keypressed(key)
    if MaquinaEstados.estado_actual and MaquinaEstados.estado_actual.Keypressed then
        MaquinaEstados.estado_actual:Keypressed(key)
    end
end