function result=pry_closeSession(session)
%  result=pry_closeSession(session)
% Closes all the open sessions in the session structure
% ARW 040313


if (isfield(session,'analogue'))
    session.analogue.release();
end

if (isfield(session,'digital'))
    session.digital.release();
end

result=session;
