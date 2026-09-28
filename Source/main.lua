-- =================== IMPORTACIONES ===================
local Enemigo = require("Enemigo")
local JugadorClass = require("Jugador")
local Habitacion = require("Habitacion")

Texturas = {}
Sonidos = {}  
local ESCALA_MUNDO = 2

-- =================== PATRÓN MÁQUINA DE ESTADOS ===================
local MaquinaEstados = {
    estado_actual = nil
}

function MaquinaEstados:Cambiar(nuevo_estado, params)
    if self.estado_actual and self.estado_actual.Salir then self.estado_actual:Salir() end
    self.estado_actual = nuevo_estado
    -- Pasamos parámetros (como el lado prohibido) al nuevo estado
    if self.estado_actual and self.estado_actual.Entrar then self.estado_actual:Entrar(params) end
end

-- =================== ESTADO: MENÚ ===================
local EstadoMenu = {}
function EstadoMenu:Entrar() end
function EstadoMenu:Update(dt) end
function EstadoMenu:Draw()
    love.graphics.printf("DECA-RUN", 0, 200, 800, "center")
    love.graphics.printf("Presiona ENTER para Iniciar", 0, 300, 800, "center")
end
function EstadoMenu:Keypressed(key)
    if key == "return" then
        MaquinaEstados:Cambiar(EstadoJugando)
    end
end

-- =================== ESTADO: JUGANDO ===================
EstadoJugando = {
    habitacion = nil, jugador = nil, enemigos = {},
    offsetX = 0, offsetY = 0,
    estado_partida = "activo"
}

function EstadoJugando:Entrar(params)
    -- Leemos el lado prohibido de la habitación anterior
    local prohibido = params and params.lado_prohibido or 0
    
    self.habitacion = Habitacion:Nueva(12, 9, prohibido)
    -- Instanciamos al jugador siempre en el centro de la sala
    self.jugador = JugadorClass:Nuevo(192, 144) 
    
    -- Le pasamos las coordenadas del jugador para evitar que los enemigos nazcan encima
    self.enemigos = self.habitacion:GenerarEnemigos(Enemigo, self.jugador.x, self.jugador.y)
    self.estado_partida = "activo"
    
    self.offsetX = (800 / ESCALA_MUNDO - (self.habitacion.ancho * self.habitacion.tam_tile)) / 2
    self.offsetY = (600 / ESCALA_MUNDO - (self.habitacion.alto * self.habitacion.tam_tile)) / 2
end

function EstadoJugando:Update(dt)
    if self.estado_partida == "derrota" then return end

    self.jugador:Actualizar(dt)

    local enemigosVivos = 0
    local jx = self.jugador.x + self.jugador.hit_ox
    local jy = self.jugador.y + self.jugador.hit_oy

    for _, enemigo in ipairs(self.enemigos) do
        if enemigo.vivo then
            enemigosVivos = enemigosVivos + 1
            enemigo:Actualizar(dt, self.jugador.x, self.jugador.y)
            
            local ex = enemigo.x + enemigo.hit_ox
            local ey = enemigo.y + enemigo.hit_oy
            
            if hayColision(jx, jy, self.jugador.hit_w, self.jugador.hit_h, ex, ey, enemigo.hit_w, enemigo.hit_h) then
                self.estado_partida = "derrota"
            end
        end
    end
    
    if enemigosVivos == 0 then 
        self.estado_partida = "victoria" 
        
        local puerta_x = self.habitacion.puerta_col * self.habitacion.tam_tile
        local puerta_y = self.habitacion.puerta_row * self.habitacion.tam_tile
        
        if hayColision(jx, jy, self.jugador.hit_w, self.jugador.hit_h, puerta_x, puerta_y, 32, 32) then
            -- Calculamos de qué lado estaba esta puerta para prohibir el lado opuesto en la siguiente
            local lado = self.habitacion.lado_puerta
            local opuesto = 0
            if lado == 1 then opuesto = 3
            elseif lado == 2 then opuesto = 4
            elseif lado == 3 then opuesto = 1
            elseif lado == 4 then opuesto = 2 end
            
            MaquinaEstados:Cambiar(EstadoJugando, {lado_prohibido = opuesto})
        end
    end
end

function EstadoJugando:Draw()
    love.graphics.push()
    love.graphics.scale(ESCALA_MUNDO, ESCALA_MUNDO)
    love.graphics.translate(self.offsetX, self.offsetY)

    self.habitacion:Dibujar(Texturas)
    self.jugador:Dibujar()
    
    for _, enemigo in ipairs(self.enemigos) do
        if enemigo.vivo then
            local frame = math.floor(enemigo.anim_index)
            if enemigo.moviendose then
                love.graphics.draw(enemigo.img_mov, enemigo.quads_mov[frame], enemigo.x, enemigo.y)
            else
                love.graphics.draw(enemigo.img_quieto, enemigo.x, enemigo.y)
            end
        end
    end
    love.graphics.pop() 

    if self.estado_partida == "derrota" then 
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("GAME OVER - Presiona R para reiniciar", 0, 250, 800, "center") 
    elseif self.estado_partida == "victoria" then 
        love.graphics.setColor(0, 1, 0)
        love.graphics.printf("SALA LIMPIA - Ve por la puerta", 0, 250, 800, "center") 
    end
    love.graphics.setColor(1, 1, 1)
end

function EstadoJugando:Keypressed(key)
    if self.estado_partida == "activo" and key == "space" then
        self.jugador:Atacar(self.enemigos)
    elseif self.estado_partida == "derrota" and key == "r" then
        MaquinaEstados:Cambiar(EstadoJugando)
    end
end

-- =================== FUNCIONES GLOBALES LÖVE2D ===================
function hayColision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x2 < x1 + w1 and y1 < y2 + h2 and y2 < y1 + h1
end

function crearAnimacion(imagen, cant_frames)
    local ancho = imagen:getWidth() / cant_frames
    local alto = imagen:getHeight()
    local quads = {}
    for i = 0, cant_frames - 1 do
        table.insert(quads, love.graphics.newQuad(i * ancho, 0, ancho, alto, imagen:getDimensions()))
    end
    return quads
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setNewFont(36) 

    Sonidos.ataque = love.audio.newSource("Sounds/ataque.mp3", "static")
    Sonidos.golpe = love.audio.newSource("Sounds/golpe.mp3", "static")

    Texturas.puerta = love.graphics.newImage("Sprites/Puerta.png")
    Texturas.esquina = love.graphics.newImage("Sprites/Esquina.png")
    Texturas.pared = love.graphics.newImage("Sprites/Pared.png")
    Texturas.piso_esquina = love.graphics.newImage("Sprites/piso_esquina.png")
    Texturas.piso_pared = love.graphics.newImage("Sprites/piso_pared.png")
    Texturas.piso_medio1 = love.graphics.newImage("Sprites/piso_medio1.png")
    Texturas.piso_medio2 = love.graphics.newImage("Sprites/piso_medio2.png")
    Texturas.piso_medio3 = love.graphics.newImage("Sprites/piso_medio3.png")
    Texturas.jugador_quieto = love.graphics.newImage("Sprites/Sprite-0002.png")
    Texturas.jugador_mov = love.graphics.newImage("Sprites/Sprite-0002pt2.png")
    Texturas.espada = love.graphics.newImage("Sprites/Espada.png")
    Texturas.slime_quieto = love.graphics.newImage("Sprites/Slime_quieto.png")
    Texturas.slime_mov = love.graphics.newImage("Sprites/Slime_moviendose.png")
    Texturas.esqueleto_quieto = love.graphics.newImage("Sprites/Esqueleto_quieto.png")
    Texturas.esqueleto_mov = love.graphics.newImage("Sprites/Esqueleto_moviendose.png")
    Texturas.arana_quieto = love.graphics.newImage("Sprites/Araña.png")
    Texturas.arana_mov = love.graphics.newImage("Sprites/Araña_movienose.png")
    
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