ALTER TABLE hub_presence
  DROP CONSTRAINT IF EXISTS hub_presence_last_emote_check;

ALTER TABLE hub_presence
  ADD CONSTRAINT hub_presence_preset_message_check
  CHECK (last_emote IN (
    '', 'wave', 'horn', 'dance',
    'chat_hello', 'chat_route', 'chat_business', 'chat_drive', 'chat_thanks'
  ));
