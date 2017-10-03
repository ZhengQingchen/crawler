defmodule Crawler.Store do
  @moduledoc """
  An internal data store for information related to each crawl.
  """

  alias __MODULE__.DB

  defmodule Page do
    @moduledoc """
    An internal struct for keeping the url and content of a crawled page.
    """

    defstruct [:url, :body, :opts, :processed]
  end

  defmodule Spec do
    @moduledoc """
    Spec for defining a store.
    """
    @type url  :: String.t
    @type body :: String.t
    @type opts :: map
    @type page :: %Page{url: url, body: body, opts: opts}

    @callback init :: {:ok, pid}
    @callback find(url :: String.t) :: page | nil
    @callback find_processed(url :: String.t) :: page | nil
    @callback add(url :: String.t) :: {:ok, page}
    @callback add_page_data(url, body, opts) :: term
    @callback processed(url :: String.t) :: term
  end

  @behaviour __MODULE__.Spec

  @doc """
  Initialises a new `Registry` named `Crawler.Store.DB`.
  """
  def init do
    Registry.start_link(keys: :unique, name: DB)
  end

  @doc """
  Finds a stored URL and returns its page data.
  """
  def find(url) do
    case Registry.lookup(DB, url) do
      [{_, page}] -> page
      _           -> nil
    end
  end

  @doc """
  Finds a stored URL and returns its page data only if it's processed.
  """
  def find_processed(url) do
    case Registry.match(DB, url, %{processed: true}) do
      [{_, page}] -> page
      _           -> nil
    end
  end

  @doc """
  Adds a URL to the registry.
  """
  def add(url) do
    Registry.register(DB, url, %Page{url: url})
  end

  @doc """
  Adds the page data for a URL to the registry.
  """
  def add_page_data(url, body, opts) do
    {_new, _old} = Registry.update_value(DB, url, & %{&1 | body: body, opts: opts})
  end

  @doc """
  Marks a URL as processed in the registry.
  """
  def processed(url) do
    {_new, _old} = Registry.update_value(DB, url, & %{&1 | processed: true})
  end
end
