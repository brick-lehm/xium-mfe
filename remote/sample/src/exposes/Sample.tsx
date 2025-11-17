import React from "react";
import {ThemeProvider} from "@brick-lehm/xium-ui";
import {SampleProps} from "sample/Sample";
import {Button} from "@mui/material";

const Sample: React.FC<SampleProps> = ({title}) => {

    return (
        <ThemeProvider defaultMode='light'>
            <div>
                <Button variant='contained' color='primary'>
                    {title}
                </Button>
            </div>
        </ThemeProvider>
    );
}
export default Sample;
