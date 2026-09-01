-- =================== IMPORTACIONES Y DECLARACIONES ===================
local Enemigo = require("Enemigo")
local JugadorClass = require("Jugador")
local Habitacion = require("Habitacion")

Texturas = {}
Sonidos = {}  
local ESCALA_MUNDO = 2

local miJugador
local miHabitacion
local offsetX, offsetY

Juego = { gameover = false, victoria = false, enemigos = {} }

-- Funciones Auxiliares
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

-- =================== INICIALIZACION ===================
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setNewFont(36) 

    Sonidos.ataque = love.audio.newSource("Sounds/ataque.mp3", "static")
    Sonidos.golpe = love.audio.newSource("Sounds/golpe.mp3", "static")

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
    
    -- Instanciar Objetos
    miHabitacion = Habitacion:Nueva(12, 9)
    miJugador = JugadorClass:Nuevo(200, 150)
    
    table.insert(Juego.enemigos, Enemigo:Nuevo(80, 80, "slime", 25))
    table.insert(Juego.enemigos, Enemigo:Nuevo(280, 80, "slime", 25))
    table.insert(Juego.enemigos, Enemigo:Nuevo(250, 150, "esqueleto", 35))
    table.insert(Juego.enemigos, Enemigo:Nuevo(250, 250, "esqueleto", 35))
    table.insert(Juego.enemigos, Enemigo:Nuevo(100, 200, "arana", 50))

    offsetX = (800 / ESCALA_MUNDO - (miHabitacion.ancho * miHabitacion.tam_tile)) / 2
    offsetY = (600 / ESCALA_MUNDO - (miHabitacion.alto * miHabitacion.tam_tile)) / 2
end

-- =================== INTERACCION ===================
function love.keypressed(key)
    if key == "space" then
        miJugador:Atacar(Juego.enemigos)
    end
end

-- =================== ACTUALIZACION ===================
function love.update(dt)
    if Juego.gameover or Juego.victoria then return end

    miJugador:Actualizar(dt)

    local enemigosVivos = 0
    local jx = miJugador.x + miJugador.hit_ox
    local jy = miJugador.y + miJugador.hit_oy

    for _, enemigo in ipairs(Juego.enemigos) do
        if enemigo.vivo then
            enemigosVivos = enemigosVivos + 1
            enemigo:Actualizar(dt, miJugador.x, miJugador.y)
            
            local ex = enemigo.x + enemigo.hit_ox
            local ey = enemigo.y + enemigo.hit_oy
            
            if hayColision(jx, jy, miJugador.hit_w, miJugador.hit_h, ex, ey, enemigo.hit_w, enemigo.hit_h) then
                Juego.gameover = true
            end
        end
    end
    
    if enemigosVivos == 0 then Juego.victoria = true end
end

-- =================== RENDERIZADO ===================
function love.draw()
    love.graphics.push()
    love.graphics.scale(ESCALA_MUNDO, ESCALA_MUNDO)
    love.graphics.translate(offsetX, offsetY)

    miHabitacion:Dibujar()
    miJugador:Dibujar()
    
    for _, enemigo in ipairs(Juego.enemigos) do
        if enemigo.vivo then
            if enemigo.moviendose then
                local frame = math.floor(enemigo.anim_index)
                love.graphics.draw(enemigo.img_mov, enemigo.quads_mov[frame], enemigo.x, enemigo.y)
            else
                love.graphics.draw(enemigo.img_quieto, enemigo.x, enemigo.y)
            end
        end
    end

    love.graphics.pop() 

    if Juego.gameover then 
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("GAME OVER", 0, 250, 800, "center") 
    end
    if Juego.victoria then 
        love.graphics.setColor(0, 1, 0)
        love.graphics.printf("HABITACION SUPERADA", 0, 250, 800, "center") 
    end
    love.graphics.setColor(1, 1, 1)
end