
  unit Test.CharacterReaderEncodingDetection;


interface

  uses
    Deltics.Smoketest;


  type
    TestCharacterReaderEncodingDetection = class(TTest)
    end;



implementation


initialization
  TestRun.Add(TestCharacterReaderEncodingDetection);

end.
