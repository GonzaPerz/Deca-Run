local Evento = { handlers = {} }

function Evento.on(event, callback)
    if not Evento.handlers[event] then Evento.handlers[event] = {} end
    table.insert(Evento.handlers[event], callback)
end

function Evento.emit(event, ...)
    if Evento.handlers[event] then
        for _, callback in ipairs(Evento.handlers[event]) do
            callback(...)
        end
    end
end

return Evento