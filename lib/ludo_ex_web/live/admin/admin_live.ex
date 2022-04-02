defmodule LudoExWeb.AdminLive do
  @moduledoc """
  Ludo Game Admin Dashboards live view module
  """
  use LudoExWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
