defmodule WaBridge.Session do
  @moduledoc """
  Stores pairing/session state for the bridge.
  """

  use GenServer

  @type state :: %{
          qr: String.t() | nil,
          paired: boolean(),
          last_error: String.t() | nil
        }

  # Public API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def put_qr(qr_string) when is_binary(qr_string) do
    GenServer.cast(__MODULE__, {:put_qr, qr_string})
  end

  def set_paired(paired) when is_boolean(paired) do
    GenServer.cast(__MODULE__, {:set_paired, paired})
  end

  def set_error(error) when is_binary(error) do
    GenServer.cast(__MODULE__, {:set_error, error})
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  # GenServer

  @impl true
  def init(_) do
    {:ok, %{qr: nil, paired: false, last_error: nil}}
  end

  @impl true
  def handle_cast({:put_qr, qr_string}, state) do
    {:noreply, %{state | qr: qr_string, last_error: nil}}
  end

  @impl true
  def handle_cast({:set_paired, paired}, state) do
    {:noreply, %{state | paired: paired, last_error: nil}}
  end

  @impl true
  def handle_cast({:set_error, error}, state) do
    {:noreply, %{state | last_error: error}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end
end
