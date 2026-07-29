_self: super: {
  brave = super.brave // {
    override =
      newArgs:
      if newArgs ? commandLineArgs && newArgs.commandLineArgs != "" then
        super.brave.overrideAttrs (old: {
          preFixup = (old.preFixup or "") + ''
            gappsWrapperArgs+=(--add-flags ${super.lib.escapeShellArg newArgs.commandLineArgs})
          '';
        })
      else
        super.brave;
  };
}
