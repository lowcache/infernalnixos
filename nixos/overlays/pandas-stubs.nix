# pandas-stubs' test suite sets filterwarnings=error (pyproject.toml) and passes
# generators to pytest.parametrize. pytest >= 9.1 promotes
# PytestRemovedIn10Warning to a hard error at collection, so all 8 tests/arrays
# collections fail. Downgrade only that warning category via PYTEST_ADDOPTS so
# the suite (and the unconditional pythonImportsCheck for pandas) still runs.
# Remove once nixpkgs bumps pandas-stubs past this test brittleness.
_final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_pyfinal: pyprev: {
      pandas-stubs = pyprev.pandas-stubs.overridePythonAttrs (old: {
        preCheck = (old.preCheck or "") + ''
          export PYTEST_ADDOPTS="$PYTEST_ADDOPTS -W ignore::pytest.PytestRemovedIn10Warning"
        '';
      });
    })
  ];
}
