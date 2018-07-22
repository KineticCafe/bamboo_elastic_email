## Contributing

We value any contribution to Bamboo.ElasticEmailAdapter you can provide: a bug
report, a feature request, or code contributions. Here are our guidelines for
contributions:

*   Changes *will not* be accepted without tests.
*   Match our coding style; we use [Credo][] and `mix format`.
*   Use a thoughtfully named topic branch that contains your change. Rebase
    your commits into logical chunks as necessary.
*   Use [quality commit messages][].
*   Do not change the version number; when your patch is accepted and a release
    is made, the version will be updated at that point.
*   Submit a GitHub pull request with your changes.

### Workflow

Here's the most direct way to get your work merged into the project:

*   Fork the project.
*   Clone down your fork (`git clone
    git://github.com/<username>/bamboo_elastic_email.git`).
*   Create a topic branch to contain your change (`git checkout -b
    my_awesome_feature`).
*   Hack away, add tests. Not necessarily in that order.
*   Make sure everything still passes with `mix test`.
*   Make sure the code is clean with `mix credo --strict`.
*   Make sure the code is clean with `mix credo --strict`.
*   If necessary, rebase your commits into logical chunks, without errors.
*   Push the branch up (`git push origin my_awesome_feature`).
*   Create a pull request against KineticCafe/bamboo\_elastic\_email and
    describe your change does and the why you think it should be merged.

### Contributors

*   Austin Ziegler created bamboo\_elastic\_email, based in part on
    [bamboo\_sparkpost][] by Andrew Timberlake.
*   Jonathan Principe upgraded to support Bamboo 1.0 and added postBack support

[quality commit messages]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
[Credo]: https://github.com/rrrene/credo
[bamboo\_sparkpost]: https://github.com/andrewtimberlake/bamboo_sparkpost
