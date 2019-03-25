defmodule Slash.Supervisor do
  @moduledoc """
  Supervisor responsible for spinning up our task supervisor and managing replies to child
  tasks.

  **This supervisor should be added to your application's supervisor if you intend on using
  async commands provided by `Slash`!**
  """

  use Supervisor

  @doc false
  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def init(_) do
    children = [
      {Task.Supervisor, name: Slash.TaskSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
