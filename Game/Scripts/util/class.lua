CLASSES = {}

ReloadClasses = function()
    print ("Checking for class reload")
    local class_copy = {}
    for k,v in pairs(CLASSES) do
        class_copy[k] = v
    end

--need to copy over statics still...
    for k,v in pairs(class_copy) do
        local modtime, errormsg = love.filesystem.getLastModified( v.file )
        --print (v.file, modtime, v.modtime)
        if modtime > v.modtime then
            print ("\tReloading class:", v.file)
            
            local chunk, error = loadfile(v.file)
            if chunk then
                local ret, error = pcall(chunk)
                if not error then
                    local newclass = CLASSES[v.class._classname]
                    if newclass then

                        newclass.class._instances = v.class._instances
                        for k,v in pairs(newclass.class._instances) do
                            setmetatable(k, newclass.class)
                        end

                        newclass.class._subclasses = v.class._subclasses
                        for k,v in pairs(newclass.class._subclasses) do
                            k._base = newclass.class
                            setmetatable( k, { __index = newclass.class, __call = k.new})
                        end

                        for k,v in pairs(v.class) do
                            if not (newclass.class[k]) then
                                newclass.class[k] = v
                            end
                        end
                    else
                        print ("could not find class definition for ", v.class._classname)
                    end

                else
                    print ("PARSE ERROR: ", error)
                end

            else
                print ("RUNTIME ERROR: ", error)
            end
            
        end
    end
end


class = function( name, baseclass )
    local cl = { }
    assert(type(name) == "string", "Class is not named")


    local name_parts = {}
    for w in string.gmatch( name, "(%a+)" ) do
        table.insert(name_parts, w)
    end

    if #name_parts > 1 then
        global(name_parts[1])
        _G[name_parts[1]] = _G[name_parts[1]] or {}
        local t = _G[name_parts[1]]

        for k = 2, #name_parts - 1 do
            t[name_parts[k]] = t[name_parts[k]] or {}
            t = t[name_parts[k]]
        end

        name = name_parts[#name_parts]
        t[name_parts[#name_parts]] = cl

    else
        global(name) 
        _G[name] = cl
    end

    cl._isa = function (self, classtype) return classtype == cl end

    cl._classname = name
    cl.__index = cl
    cl._base = baseclass
    if baseclass then
        baseclass._subclasses[cl] = true
    end
    cl._instances = setmetatable( {}, { __mode = 'k' })
    cl._subclasses = {}

    cl.new = function(self, ...)
        local inst = {}
        setmetatable(inst, cl)
        
        cl._instances[inst] = true
        
        if cl.init then
            cl.init(inst, ...)
        end

        return inst    
    end

    if baseclass then

        --metamethods are looked up with rawget, so we have to copy tostring forward manually
        if baseclass.__tostring and not cl.__tostring then
            cl.__tostring = baseclass.__tostring
        end

        setmetatable( cl, { __index = baseclass, __call = cl.new})
    else
        setmetatable( cl, { __call = cl.new})
    end

    local deffile = debug.getinfo(2, "S").source
    deffile = string.gsub(deffile, "^@", "")
    local modtime, errormsg = love.filesystem.getLastModified( deffile )
    CLASSES[cl._classname] = {class= cl, file=deffile, modtime= modtime}

    return cl
end

is_class = function(obj, class)
    return obj.__index == class 
end

