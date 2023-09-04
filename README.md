<!-- Please do not edit the README.md file as it is auto-generated after PR merges. Only edit the README.Rmd file -->
<!-- The purpose of this is to enable dynamic links using dyn_link function above to access devel/main admiral homepage respectively -->
<!-- To test this in your feature branch use code: rmarkdown::render("README.Rmd", output_format ="md_document") -->

# admiral package extension Template <img src="man/figures/logo.png" align="right" width="200" style="margin-left:50px;"/>

<!-- badges: start -->

[<img src="http://pharmaverse.org/shields/admiral.svg">](https://pharmaverse.org)
[![CRAN
status](https://www.r-pkg.org/badges/version/admiral)](https://CRAN.R-project.org/package=admiral)
[![Test
Coverage](https://raw.githubusercontent.com/pharmaverse/admiraltemplate/badges/main/test-coverage.svg)](https://github.com/pharmaverse/admiraltemplate/actions/workflows/code-coverage.yml)
<!-- badges: end -->

## Table of Contents

-   [Extension Expectations](#extension-expectations)
-   [What is included in the
    template](#what-is-included-in-the-template)
-   [Package Extension Guidance](#package-extension-guidance)
-   [Quick Start Guide for Template](#quick-start-guide-for-template)

## Extension Expectations

To be included as an `{admiral}` package extension we expect developers
to adhere to the following standards:

-   [Code of
    Conduct](https://pharmaverse.github.io/admiral/main/CODE_OF_CONDUCT.html)
-   [Manifesto](https://pharmaverse.github.io/admiral/main/index.html?q=manifest#admiral-manifesto)
-   [Programming
    Strategy](https://pharmaverse.github.io/admiraldev/main/articles/programming_strategy.html)
-   [Development
    Process](https://pharmaverse.github.io/admiraldev/main/articles/development_process.html)
-   Follow consistent workflow checks
-   A CRAN Release means 90% or greater test coverage

We have developed this repository template in order to reduce the burden
on developers to follow these standards. This template will also help to
harmonize the `{admiral}` family of R packages, to ensure a consistent
user experience and ease of installing and adopting all the packages.
With this in mind, we expect the same core package dependencies and
versions as used for `{admiral}`.

## What is included in the template

The repository template includes the following:

-   License file (Apache 2.0 - but company co-developers need to be
    added to copyright section)
-   Required folders (R; test; templates; vignettes; renv; etc)
-   Set-up files (DESCRIPTION; NAMESPACE; renv.lock; etc)
-   Issue Templates (Bug Template; Feature Request; Documentation
    Request/Update; Onboarding)
-   Pull Request Template
-   Workflow actions (a selection of generic and specific CI/CD
    auto-checks)
-   Package badges (Test coverage; etc)
-   Branch protection rules

## Package Extension Guidance

`{admiral}` is made up of a family of packages and we foresee this only
growing over time to cover more specific areas such as TA (Therapeutic
Area) package extensions, with a wider range of companies and
individuals getting on board to join development efforts. This
step-by-step guidance talks through our recommendations on how new
development teams would go about creating such package extensions. It is
critical that this guidance is followed, as our users need to feel a
consistent experience when working across `{admiral}` packages. If an
admiral package extension doesn’t follow these conventions then we
wouldn’t include it under pharmaverse and as part of the `{admiral}`
family.

*Note: The ordering numbers below are suggested but don’t all need to
strictly be followed in this sequence.*

1.  Raise the need for a new `{admiral}` package extension with the
    sponsors (Ross Farrugia <ross.farrugia@roche.com> & Ben Arancibia
    <benjamin.c.arancibia@gsk.com>). The naming convention needs to be
    `{admiralxxx}` and we request that the scope is not targeted overly
    narrow, for example instead of a package extension for HIV we’d
    prefer one across virology. Otherwise the number of packages may
    become unmanageable.
2.  Once agreed, reach out to other company contacts working in similar
    areas to see if a collaborative development can be achieved. *Our
    recommendation here is always to target at least 2 companies to
    start so that any implementation remains robust and we protect from
    going down a company-specific route. However, consider that if more
    than 4 or 5 companies get involved too early it may slow down
    decision-making.*
3.  From the companies that agree to co-develop, identify a lead from
    each. One company should act as the driver for the overall package
    extension and put forward a product owner and technical lead who
    ultimately have final say on any contentious decisions. The product
    owner would cover project decisions (e.g. around scope and
    priorities), whereas the technical lead would cover technical
    decisions (e.g. around design and implementation). *Ideally, the
    technical lead should have had some earlier involvement in
    `{admiral}` such as being part of the core development team or as a
    contributor, as this is a key role in order to keep the design true
    to the manifesto.*
4.  Agree on a charter and expectations of each company, e.g. we usually
    ask for at least 3 developers with at least 25% capacity and a mix
    of R, GitHub and TA experience. Within the charter make sure the
    scope and timelines are clear. *It is important here not to try to
    boil the ocean. Focus first on the very common endpoints required as
    a foundation and then the package can build up from here via
    contributions from both the co-development companies and also the
    wider across-industry admiral community. If useful, the
    `{admiralonco}` charter could be shared as a guide.*
5.  Each company should start to identify the required developer
    resources. Then they all need to attend one of the monthly admiral
    onboarding sessions (as advertised via our Slack channel - which
    they should join using this
    [link](https://join.slack.com/t/pharmaverse/shared_invite/zt-yv5atkr4-Np2ytJ6W_QKz_4Olo7Jo9A)).
    All should read up on the admiral
    [site](https://pharmaverse.github.io/admiral/main/), especially the
    developer guides which all need to be followed for package
    extensions.
6.  Optionally it can be useful to host a kick-off meeting to decide how
    the team will work, for which we recommend agile/scrum practices.
7.  Set up a “admiralxxx\_dev” channel on Slack to add all team members
    to for informal team chat, and agree a way to share working
    documents across the co-development team.
8.  A useful starter development activity could be to look into
    `{admiral.test}` to check that the test data there is sufficient for
    your TA needs, e.g. for `{admiralonco}` we had to generate new test
    data for SDTM domains such as RS and TU. Note that no personal data
    should be used here (even if anonymized) and it is important to keep
    any data generated in-line with the CDISC pilot data we use here,
    i.e. use same USUBJIDs as DM etc.
9.  Optionally draft, agree and sign a collaboration agreement if the
    collaborating companies so wish, as this could be useful for
    protecting secondary IP such as company standard specifications that
    may be shared within the team. An example is stored
    [here](https://github.com/pharmaverse/pharmaverse/blob/main/content/contribute/Pharmaverse%20Collaborative%20Agreement%20(template).docx),
    but work with your Legal teams as required.
10. Share company-specific implementations and specifications to be able
    to harmonize into your design strategy for the package extension.
    *Here it is important to remain pragmatic and consider a higher
    perspective than any one company. Engage your company standards
    representatives and where you find discrepancies across company
    approaches then question if you really need to be doing things
    differently here (do health authorities or patients benefit at all
    if you do?). Also consider that we always expect a level of
    company-specifics to be covered in the internal company package
    extensions.*
11. Set up a new public GitHub repo under the [pharmaverse
    org](https://github.com/pharmaverse) using
    [admiraltemplate](https://github.com/pharmaverse/admiraltemplate) -
    this includes set-up pieces (such as CI/CD checks and issue/PR
    templates) that will enable your package to stay consistent with
    others in the admiral family, as well as the same core package
    dependencies and versions. See Quick Start Guide for Template
    section below for instructions. *Note that this step requires org
    member access which could be granted by of the pharmaverse council
    reps, who are admins for this org. Also you are free to add
    additional package dependencies as needed assuming only reliable
    packages are used, but they must not depend on newer versions of
    other packages (always reply “no” if updates are suggested during
    installation).*
12. Once the repo is available the technical lead could be granted admin
    access to this repo and then could set up a GitHub team with the
    same name as the package extension to assign required access for all
    other co-development team members. Most will only require write
    access, but you may choose to give the other leads admin access as
    well so that never a bottle-neck waiting on one person.
13. Update the template license file in your repo by adding the
    co-development company names in place of Roche & GSK - for
    `{admiral}` package extensions we use Apache 2.0, which is our
    preferred permissive license. Agree with the co-development
    companies any required extra wording for the copyright/IP section.
14. Set up a project board, such as
    [this](https://github.com/orgs/pharmaverse/projects/12), to help
    manage your backlog.
15. Assuming you work under agile/scrum, then create a product backlog,
    prioritize and make a sprint plan.
16. The intention is always to re-use as much as possible from
    `{admiral}` core package. If you find anything additional needed for
    the package extension, you should first question whether it might be
    a common need for other TAs and if so consider instead raising an
    issue to `{admiral}` core. When designing new functions always try
    to stay aligned with the [programming
    strategy.](https://pharmaverse.github.io/admiraldev/main/articles/programming_strategy.html).
17. Start development of your foundational first release 0.1.0. Follow a
    consistent [development
    process](https://pharmaverse.github.io/admiraldev/main/articles/development_process.html)
    to `{admiral}`.
18. Line up testers from your companies and others and set expectations
    around when you believe a stable version would be available for user
    testing. You can use the admiral Slack community to raise interest
    to get involved.
19. Add a pharmaverse badge to your README:
    <https://pharmaverse.org/contribute/badges/> - needs support from a
    pharmaverse council rep.
20. Raise an `{admiral}` repo issue to ensure your package extension
    site is linked from the core `{admiral}` site
    [here.](https://pharmaverse.github.io/admiral/main/index.html#types-of-packages)
21. It is important that the `{admiral}` family of packages keep to a
    similar release schedule and cadence, in order to ease adoption by
    our users and to give clear expectations. The `{admiral}` core
    package cadence of releases is one every quarter on a fixed schedule
    (every first Monday of the last month of a quarter - March, June,
    September, December). The core package will set the release schedule
    for the package extensions to follow, i.e. once `{admiral}` releases
    we’d expect package extension releases targeted within a 2 week
    window. These releases are communicated via our Slack channel as
    well as at our quarterly user community meetings.
22. Once you are happy your package extension has been well tested and
    is at a sufficient state then make a submission to CRAN. The
    technical lead should be named as maintainer. After the CRAN
    release, you should advertise this via Slack & LinkedIn.
23. Plan any future further enhancements and make issues. When your team
    feels ready you can open up to development contributions for these
    from the wider community - see [this
    page.](https://pharmaverse.github.io/admiral/main/CONTRIBUTING.html#type-1-contribution-with-code).
    Please use the *“good first issue”* (ideal for new starters) &
    *“help wanted”* (ideal for more experienced contributors) issue
    labels.

## Quick Start Guide for Template

Please thoroughly read the Package Extension Guidance above. The
intention of the Quick Start is to just get the template code into a new
repo and check that the package works in your environment. Please
contact us via slack if any issues arise.

1.  Click the Green `Use this Template` Button.
2.  Change owner to `pharmaverse` and enter your repository name
3.  Create `devel` and `patch` branches. These will be important later
    for workflows!
4.  Once repo has been created click Green Code button and download the
    repo using `https` or `ssh`
5.  Run `renv::restore()` - you will see a prompt and this will take a
    few minutes
    -   This will ensure that your development environment for your
        extension package is synced with other admiral packages
6.  Update/Remove the following files to use your extension name:
    -   `DESCRIPTION` File - Name, Authors
    -   `admiralext.Rproj`
    -   `testthat.R`
    -   `News.md`
7.  Run `devtools::load_all()` and resolve issues
8.  Run `devtools::document()` and resolve issues
9.  Run `pkgdown::build_site()`
    -   Reach out to slack for help with creating a hex sticker/logo to
        replace pharmaverse logo
10. *Recommended*: Review the [documentation on the CI/CD
    workflows](https://pharmaverse.github.io/admiralci/main/#what-these-workflows-do)
    for information about how to reuse the workflows from this template.
    Pay special attention to the section on creating the `badges` orphan
    branch in [this
    section](https://pharmaverse.github.io/admiralci/main/#code-coverage).
11. Test out a dummy branch and do a Pull Request to ensure CI/CD works.
12. Any clearly dummy files like `R/my_first_fcn.R` or
    `inst/templates/ad_adxx.R` can be updated or removed.
13. Set up [branch protections
    rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/managing-a-branch-protection-rule)
    for `main`, `devel`, and optionally for `pre-release` and `test`
    depending on your branching strategy.
14. Set up and assign admin and write rights in Settings/Collaborators
    for members of the repository - using a GitHub team for all
    developers.
15. Change badges and hex image in `README.Rmd` to your package.
