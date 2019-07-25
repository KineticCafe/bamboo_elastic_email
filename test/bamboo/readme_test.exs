defmodule Bamboo.ReadmeTest do
  @moduledoc false

  # Neat idea provided by Brian Cardarella on the Dockyard blog:
  # https://dockyard.com/blog/2019/02/22/keep-your-readme-install-instructions-up-to-date

  use ExUnit.Case

  @app :bamboo_elastic_email
  @version to_string(Application.spec(@app, :vsn))

  test "README install version check" do
    readme = File.read!("README.md")
    [_, readme_versions] = Regex.run(~r/{:#{@app}, "(.+)"}/, readme)

    assert Version.match?(@version, readme_versions),
           """
           Install version constraint in README.md does not match to current app version.
           Current App Version: #{@version}
           Readme Install Versions: #{readme_versions}
           """
  end
end
