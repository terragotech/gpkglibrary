package com.reactlibrary.enums;

/**
 * Created by ram on 24/02/17.
 */

public enum NotesType {
        none(1),image(2),audio(3),video(4),group(5),forms(6),attachment(7),file(8),location(9),multiupload(10);

        private final int notesType;

        NotesType(int notesType){
            this.notesType = notesType;
        }

        public int getValue(){
            return notesType;
        }
}
