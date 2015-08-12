defmodule News.Util.TempFile do

  def write(name, data) do
    file = "/tmp/news.temp." <> name
    :ok = File.write!(file, data)
    parent = self
    monitor_file(file)
  end

  def attach(file) do
    monitor_file(file)
  end

  def release do
    pid = Process.get(:temp_file_pid)
    if pid do
      send(pid, :release)
      Process.delete(:temp_file_pid)
    end
  end

  def monitor_loop(files) do
    receive do
      {:monitor, file} -> monitor_loop([file|files])
      _ ->
        Enum.each(files, fn(file) -> File.rm(file) end)
        exit(:normal)
    end
  end

  defp monitor_file(file) do
    pid = Process.get(:temp_file_pid)
    if pid do
      send(pid, {:monitor, file})
    else
      parent = self
      pid = spawn(fn() ->
        _ref = Process.monitor(parent)
        monitor_loop([file])
      end)
      Process.put(:temp_file_pid, pid)
    end
    file
  end

end
