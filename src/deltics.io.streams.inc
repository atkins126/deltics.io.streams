
{$i deltics.inc}

{$debuginfo OFF}

{$ifdef debug_DelticsIo}
  {$define debug_DelticsIoStreams}
{$endif}

{$ifdef debug_DelticsIoStreams}
  {$undef InlineMethods}
  {$debuginfo ON}
{$endif}