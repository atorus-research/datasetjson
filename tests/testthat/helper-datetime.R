# Every write stamps datasetJSONCreationDateTime with the current second, so two
# writes that straddle a second boundary differ in that one field. Tests that
# compare the output of separate writes pin the clock so a slow machine can't
# make them fail.
local_frozen_datetime <- function(value = "2026-01-01T00:00:00",
                                  env = parent.frame()) {
  local_mocked_bindings(get_datetime = function() value,
                        .package = "datasetjson", .env = env)
}
