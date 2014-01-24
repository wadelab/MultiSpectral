function closedSession=pry_closeSession(session)
%  result=pry_closeSession(session)
% Closes all the open sessions in the session structure
% ARW 040313


if (isfield(session,'analogue'))
        session.analogue.session.stop();
    session.analogue.session.release();
end

if (isfield(session,'digital'))
     session.digital.session.stop();
    session.digital.session.release();
end

closedSession=session;
