--!strict
--[[
	debug.getproto Usage Examples
	
	This function returns a specific function prototype from a Luau function by index.
	It throws an error if called on a C closure (like print).
	
	Parameters:
	- func: The Luau function (or stack level) to extract a proto from.
	- index: The index of the prototype to return.
	- activated?: If true, returns a table of currently active functions based on the proto.
	
	Returns:
	- Without activated: (...any) -> (...any) | { (...any) -> (...any) }
	- With activated=true: { (...any) -> (...any) }
]]

-- Example 1: Retrieving nested prototypes (inactive protos - uncallable)
print("=== Example 1: Inactive Prototypes ===")

local function dummy_function()
	local function dummy_proto_1()
		print("Hello from proto 1")
	end
	local function dummy_proto_2()
		print("Hello from proto 2")
	end
end

-- These return inactive protos - they exist in bytecode but are not callable
local proto1 = debug.getproto(dummy_function, 1)
local proto2 = debug.getproto(dummy_function, 2)

print("Retrieved proto 1:", type(proto1)) -- Should be "function" but uncallable
print("Retrieved proto 2:", type(proto2)) -- Should be "function" but uncallable

-- Calling these would fail as they are inactive
-- proto1() -- Would error or not work as expected


-- Example 2: Retrieving an active function from a proto
print("\n=== Example 2: Active Prototype ===")

local function dummy_function_active()
	local function dummy_proto()
		return "hi"
	end
	return dummy_proto
end

local real_proto = dummy_function_active()
local retrieved_protos = debug.getproto(dummy_function_active, 1, true) -- activated=true
local retrieved_proto = retrieved_protos[1]

if retrieved_proto then
	print("real_proto == retrieved_proto:", real_proto == retrieved_proto) -- Output: true
	print("retrieved_proto():", retrieved_proto()) -- Output: hi
end


-- Example 3: Error handling with C closures
print("\n=== Example 3: C Closure Error Handling ===")

local success, result = pcall(function()
	debug.getproto(print, 1) -- print is a C closure, this should throw an error
end)

if not success then
	print("Expected error when calling debug.getproto on C closure:", result)
end


-- Example 4: Multiple nested functions
print("\n=== Example 4: Multiple Nested Functions ===")

local function outer_function()
	local function inner_1()
		return 1
	end
	local function inner_2()
		return 2
	end
	local function inner_3()
		return 3
	end
end

-- Get all inactive protos
for i = 1, 3 do
	local proto = debug.getproto(outer_function, i)
	print(`Proto {i} type:`, type(proto))
end


-- Example 5: Active vs Inactive comparison
print("\n=== Example 5: Active vs Inactive Comparison ===")

local function factory()
	local function template()
		return "I'm a template"
	end
	return template
end

-- Create an actual instance
local actual_function = factory()

-- Get inactive proto (from bytecode definition)
local inactive_proto = debug.getproto(factory, 1)
print("Inactive proto type:", type(inactive_proto))

-- Get active proto (actual runtime function)
local active_protos = debug.getproto(factory, 1, true)
local active_proto = active_protos[1]

if active_proto then
	print("Active proto matches actual:", active_proto == actual_function)
	print("Active proto result:", active_proto())
end

print("\n=== All examples completed ===")
