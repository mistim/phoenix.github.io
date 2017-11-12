defmodule Translate do
  @url "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ru&dt=t&q="
  @origin_doc "{:.origin_doc}"
  
  def get(text) do
    case HTTPoison.get(@url <> text, ["Accept": "Application/json; Charset=utf-8"], [ssl: [{:versions, [:'tlsv1.2']}]]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        parse_response(body)
      {:ok, %HTTPoison.Response{status_code: 301}} ->
        raise("Incorrect URL")
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts "Not found :("
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end
  end

  def parse_response(response) do
    [result|_] = response
    |> Poison.decode!

    result
    |> Enum.map_join(" ", fn(item) -> 
      List.first(item) 
      |> String.trim()
      |> String.replace("«", "`") 
      |> String.replace("»", "`")  
      |> String.replace(" / ", "/")
      |> String.replace("`/ ", "`/")
      |> String.replace("] (", "](")
      |> String.replace(~r/(`\s)([A-Za-z0-9_:\/]{a-z]{1})/, " `\\g{2}")
    end)
  end

  def read_file(file) do
    file_path = Path.join(~w(#{Path.absname("docs_en")} #{file}))
    
    case File.read(file_path) do
      {:ok, body}      -> parse_text body, file
      {:error, _} -> IO.puts "error"
    end
  end

  def parse_text(text, file) do
    {:ok, file} = Path.join(~w(#{Path.absname("docs")} #{file}))
    |> File.open([:write])

    String.split(text, ~r(\r\n\r\n), trim: true)
    |> Enum.each(fn(item) ->
      if String.replace(item, ~r(\r\n), "") |> String.ends_with?(@origin_doc) do
        new_item = String.replace(item, @origin_doc, "") 
        |> URI.encode() 
        |> String.replace("#", "%23")
        |> get() 
        
        item = String.replace(item, ~r/^[#]{1,7}\s/, "")

        IO.binwrite file, "#{item}\r\n\r\n"
        IO.binwrite file, "#{new_item}\r\n\r\n"
      else
        IO.binwrite file, "#{item}\r\n\r\n"
      end
    end)

    File.close file
    # File.read file_path
  end

  def test() do
    "### When we run `$ mix phoenix.routes` now, in addition to the routes we saw for `users` above, we get the following set of routes:"
    |> URI.encode()
    |> String.replace("#", "%23")
    |> get()
    |> IO.puts()
  end
end


# defmodule Mix.Tasks.Translate do
#   use Mix.Task

#   @url "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ru&dt=t&q="

#   def run(_args) do
#     [t|h] = _args
#     HTTPoison.get(@url <> t, ["Accept": "Application/json; Charset=utf-8"], [ssl: [{:versions, [:'tlsv1.2']}]])
    
#     # Translate.get(t)
#   end
# end

