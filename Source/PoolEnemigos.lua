local EnemigoClass = require("Enemigo")

local PoolEnemigos = {}
PoolEnemigos.__index = PoolEnemigos

function PoolEnemigos:Nuevo(tamano)
    local o = setmetatable({}, PoolEnemigos)
    o.pool = {}
    -- Preasignación en un bloque continuo
    for i = 1, tamano do
        o.pool[i] = EnemigoClass:Nuevo(0, 0, "slime", 0)
        o.pool[i].vivo = false -- Desactivados por defecto
    end
    return o
end

function PoolEnemigos:Obtener(x, y, tipo, vel)
    for i = 1, #self.pool do
        if not self.pool[i].vivo then
            -- Reutilizamos el objeto existente
            self.pool[i]:Reconfigurar(x, y, tipo, vel)
            return self.pool[i]
        end
    end
    return nil -- El Pool está lleno
end

function PoolEnemigos:Limpiar()
    for i = 1, #self.pool do
        self.pool[i].vivo = false
    end
end

function PoolEnemigos:Actualizar(dt, px, py)
    local vivos = 0
    for i = 1, #self.pool do
        local e1 = self.pool[i]
        if e1.vivo then
            vivos = vivos + 1
            e1:Actualizar(dt, px, py)
            
            -- Repulsión iterando sobre el mismo bloque de datos
            for j = 1, #self.pool do
                local e2 = self.pool[j]
                if i ~= j and e2.vivo then
                    local dx, dy = e1.x - e2.x, e1.y - e2.y
                    local dist = math.sqrt(dx^2 + dy^2)
                    if dist < 25 and dist > 0.1 then
                        e1.x = e1.x + (dx / dist) * 40 * dt
                        e1.y = e1.y + (dy / dist) * 40 * dt
                    end
                end
            end
        end
    end
    return vivos
end

return PoolEnemigos