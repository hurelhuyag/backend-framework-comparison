import { IsNotEmpty, IsString } from "class-validator";

export class UpdateContentRequest {
    @IsString()
    @IsNotEmpty()
    content: string;
}
