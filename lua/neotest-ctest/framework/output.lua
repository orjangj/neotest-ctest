local M = {}

function M.normalize(output)
  output = output:gsub("\r\n", "\n")
  return (
    output:gsub("[^\n]+", function(text)
      local file, line, suffix = text:match("^(.-%.[%w_]+)%((%d+)%)(.*)$")
      if file and (suffix == "" or suffix:sub(1, 1) == ":") then
        return file .. ":" .. line .. suffix
      end
      return text
    end)
  )
end

return M
