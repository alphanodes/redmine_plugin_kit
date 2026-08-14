# frozen_string_literal: true

# Probe for the reload behaviour of Loader#reload_on_prepare: records that the
# file has been loaded, so a test can tell a repeated load from a no-op require.
ReloadProbe.loaded << 'first'
